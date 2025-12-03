package com.ipcamera.ip_camera_streaming.serv

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import java.net.Inet4Address
import java.net.NetworkInterface

class NetworkMonitor(private val context: Context) {
    private val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    private var networkCallback: ConnectivityManager.NetworkCallback? = null
    private var onNetworkChanged: ((String, String) -> Unit)? = null
    
    fun startMonitoring(onChanged: (String, String) -> Unit) {
        this.onNetworkChanged = onChanged
        
        val networkRequest = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()
        
        networkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                super.onAvailable(network)
                notifyNetworkChange()
            }
            
            override fun onLost(network: Network) {
                super.onLost(network)
                notifyNetworkChange()
            }
            
            override fun onCapabilitiesChanged(
                network: Network,
                networkCapabilities: NetworkCapabilities
            ) {
                super.onCapabilitiesChanged(network, networkCapabilities)
                notifyNetworkChange()
            }
        }
        
        connectivityManager.registerNetworkCallback(networkRequest, networkCallback!!)
    }
    
    fun stopMonitoring() {
        networkCallback?.let {
            connectivityManager.unregisterNetworkCallback(it)
        }
        networkCallback = null
    }
    
    fun getCurrentNetwork(): Map<String, String> {
        val networkType = getNetworkType()
        val ipAddress = getCurrentIPAddress()
        return mapOf(
            "networkType" to networkType,
            "ipAddress" to ipAddress
        )
    }
    
    private fun notifyNetworkChange() {
        val networkType = getNetworkType()
        val ipAddress = getCurrentIPAddress()
        onNetworkChanged?.invoke(networkType, ipAddress)
    }
    
    private fun getNetworkType(): String {
        val activeNetwork = connectivityManager.activeNetwork ?: return "none"
        val capabilities = connectivityManager.getNetworkCapabilities(activeNetwork) ?: return "none"
        
        return when {
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "cellular"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
            else -> "unknown"
        }
    }
    
    private fun getCurrentIPAddress(): String {
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement()
                
                if (networkInterface.isLoopback || !networkInterface.isUp) {
                    continue
                }
                
                val addresses = networkInterface.inetAddresses
                while (addresses.hasMoreElements()) {
                    val address = addresses.nextElement()
                    
                    if (address is Inet4Address && !address.isLoopbackAddress) {
                        return address.hostAddress ?: ""
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        return ""
    }
}
