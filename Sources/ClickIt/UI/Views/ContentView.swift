//
//  ContentView.swift
//  ClickIt
//
//  Created by ClickIt on 2025-07-13.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var permissionManager: PermissionManager
    @EnvironmentObject private var hotkeyManager: HotkeyManager
    @EnvironmentObject private var viewModel: ClickItViewModel
    @StateObject private var updaterManager = UpdaterManager()
    @State private var showingPermissionSetup = false
    @State private var showingUpdateSettings = false
    
    var body: some View {
        if permissionManager.allPermissionsGranted {
            // Modern UI when permissions are granted
            modernUIView
        } else {
            // Permission setup view
            permissionSetupView
        }
    }
    
    @ViewBuilder
    private var modernUIView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Status Header Card
                StatusHeaderCard(viewModel: viewModel)
                
                // Development Update Button (Phase 1 MVP)
                #if DEBUG
                if AppConstants.DeveloperUpdateConfig.enabled {
                    DeveloperUpdateButton(updaterManager: updaterManager)
                }
                #endif
                
                // Update Notification (if available)
                if updaterManager.isUpdateAvailable || updaterManager.isCheckingForUpdates {
                    UpdateNotificationCard(updaterManager: updaterManager)
                }
                
                // Target Point Selection Card
                TargetPointSelectionCard(viewModel: viewModel)
                
                // Configuration Panel Card
                ConfigurationPanelCard(viewModel: viewModel)
                
                // Footer Information
                FooterInfoCard()
                    .padding(.top, 20)
            }
            .padding(16)
        }
        .frame(width: 400, height: 800)
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            permissionManager.updatePermissionStatus()
            
            // Check for updates on app launch (respecting development configuration)
            #if DEBUG
            // In development builds, only manual checking is enabled
            if !AppConstants.DeveloperUpdateConfig.manualCheckOnly,
               updaterManager.autoUpdateEnabled,
               let timeSinceLastCheck = updaterManager.timeSinceLastCheck,
               timeSinceLastCheck > AppConstants.updateCheckInterval {
                updaterManager.checkForUpdates()
            }
            #else
            // In production builds, use normal automatic checking
            if updaterManager.autoUpdateEnabled,
               let timeSinceLastCheck = updaterManager.timeSinceLastCheck,
               timeSinceLastCheck > AppConstants.updateCheckInterval {
                updaterManager.checkForUpdates()
            }
            #endif
        }
    }
    
    @ViewBuilder
    private var permissionSetupView: some View {
        VStack(spacing: 20) {
            // App Icon
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            // App Title
            Text("ClickIt")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Subtitle
            Text("Precision Auto-Clicker for macOS")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Permission Status
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.shield")
                            .foregroundColor(.orange)
                        Text("Permissions Required")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                    
                    Text("ClickIt requires accessibility and screen recording permissions to function properly.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Setup Permissions") {
                        showingPermissionSetup = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(20)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                
                // Compact permission status
                CompactPermissionStatus()
            }
            
            Spacer()
            
            // Version Info
            FooterInfoCard()
        }
        .padding(24)
        .frame(width: 400, height: 800)
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            permissionManager.updatePermissionStatus()
        }
        .sheet(isPresented: $showingPermissionSetup) {
            PermissionRequestView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PermissionManager.shared)
        .environmentObject(HotkeyManager.shared)
        .environmentObject(ClickItViewModel())
}
