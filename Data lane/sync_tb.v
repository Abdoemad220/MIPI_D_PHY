`timescale 1ns / 1ps

module tb_sync;
    // Inputs
    reg clk;
    reg rst;
    reg unstable;
    
    // Outputs
    wire stable;
    
    // Instantiate the Unit Under Test (UUT)
    sync uut (
        .clk(clk),
        .rst(rst),
        .unstable(unstable),
        .stable(stable)
    );
    
    // Clock generation (100MHz)
    always #5 clk = ~clk;
    
    // Test sequence
    initial begin
        // Initialize inputs
        clk = 0;
        rst = 0;
        unstable = 0;
        
        // Test Case 1: Reset assertion
        $display("\n=== Test Case 1: Reset ===");
        #10;
        rst = 1;  // Assert reset (active high)
        #20;
        rst = 0;  // Deassert reset
        #10;
        
        // Test Case 2: Basic synchronization
        $display("\n=== Test Case 2: Basic Synchronization ===");
        unstable = 1;
        #40;
        unstable = 0;
        #40;
        
        // Test Case 3: Multiple transitions
        $display("\n=== Test Case 3: Multiple Transitions ===");
        repeat (3) begin
            unstable = 1;
            #30;
            unstable = 0;
            #30;
        end
        
        // Test Case 4: Reset during operation
        $display("\n=== Test Case 4: Reset During Operation ===");
        unstable = 1;
        #25;
        rst = 1;  // Assert reset while signal is high
        #20;
        rst = 0;  // Deassert reset
        #20;
        
        // Test Case 5: Setup/hold violation simulation
        $display("\n=== Test Case 5: Setup/Hold Violation Simulation ===");
        unstable = 0;
        #10;
        
        // Try to create setup/hold violations by changing near clock edge
        repeat (4) begin
            #2;  // Change just before clock edge (setup violation)
            unstable = ~unstable;
            #8;  // Wait past clock edge
        end
        
        // Test Case 6: Long stable signal
        $display("\n=== Test Case 6: Long Stable Signal ===");
        unstable = 1;
        #100;
        unstable = 0;
        #100;
        
        // Test Case 7: Rapid toggling
        $display("\n=== Test Case 7: Rapid Toggling ===");
        repeat (8) begin
            unstable = ~unstable;
            #6;  // Faster than clock period
        end
        
        #50;
        $display("\n=== Test Complete ===");
        $finish;
    end
    
    // Monitor to display signal changes
    always @(posedge clk) begin
        $display("%0t ns\t%b\t%b\t\t%b", $time, rst, unstable, stable);
    end
    
    // Check for proper synchronization behavior
    always @(posedge clk) begin
        if (!rst) begin
            // Check that stable follows unstable with 2-cycle delay
            // This is a basic check - real metastability can't be detected in simulation
            if (stable !== uut.stage2) begin
                $display("ERROR: Synchronization stages inconsistent!");
            end
        end
    end
    
    // Reset monitoring
    always @(posedge rst) begin
        $display("RESET asserted at time %0t ns", $time);
    end
    
    always @(negedge rst) begin
        $display("RESET deasserted at time %0t ns", $time);
    end
endmodule