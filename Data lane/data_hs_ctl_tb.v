`timescale 1ns / 1ps

module tb_Data_HS_CTL;
    // Inputs
    reg          clk;
    reg          rst;
    reg          Serial_End;
    reg          hs_en;
    reg          TxDataTransferEnHS;
    reg          TxWordValidHS;
    reg          time_done;
    reg  [31:0]  TxDataHS;
    
    // Outputs
    wire         TxRdHS;
    wire         Serial_En;
    wire         Trail;
    wire         Trail_sel;
    wire         Sync_dn;
    wire         time_reset;
    wire         Serial_Valid;
    wire         timer_enable;
    wire         valid_done;
    wire [7:0]   HS_prll_data;
    
    // Instantiate the Unit Under Test (UUT)
    Data_HS_CTL uut (
        .clk(clk),
        .rst(rst),
        .Serial_End(Serial_End),
        .hs_en(hs_en),
        .TxDataTransferEnHS(TxDataTransferEnHS),
        .TxWordValidHS(TxWordValidHS),
        .time_done(time_done),
        .TxDataHS(TxDataHS),
        .TxRdHS(TxRdHS),
        .Serial_En(Serial_En),
        .Trail(Trail),
        .Trail_sel(Trail_sel),
        .Sync_dn(Sync_dn),
        .time_reset(time_reset),
        .Serial_Valid(Serial_Valid),
        .timer_enable(timer_enable),
        .valid_done(valid_done),
        .HS_prll_data(HS_prll_data)
    );
    
    // Clock generation
    always #5 clk = ~clk; // 100MHz clock
    
    // Test sequence
    initial begin
        // Initialize inputs
        clk = 0;
        rst = 1;
        Serial_End = 0;
        hs_en = 0;
        TxDataTransferEnHS = 0;
        TxWordValidHS = 0;
        time_done = 0;
        TxDataHS = 32'h00000000;
        
        // Apply reset
        #20;
        rst = 0;
        #20;
        
        // Test Case 1: Normal operation sequence
        $display("Test Case 1: Normal operation sequence");
        hs_en = 1;
        #20;
        
        // Wait for HS0 state and simulate timer done
        #50;
        time_done = 1;
        TxDataTransferEnHS = 1;
        #10;
        time_done = 0;
        
        // Simulate serial end for sync sequence
        #30;
        Serial_End = 1;
        #20;
        Serial_End = 0;
        
        // Provide valid data for HS_DATA state
        TxWordValidHS = 1;
        TxDataHS = 32'hA5A5A5A5;
        #40;
        
        // Change data
        TxDataHS = 32'h12345678;
        #40;
        
        // End data transmission
        TxWordValidHS = 0;
        #40;
        
        // Wait for trail state completion
        #100;
        
        // Test Case 2: Reset during operation
        $display("Test Case 2: Reset during operation");
        hs_en = 1;
        TxDataTransferEnHS = 1;
        TxWordValidHS = 1;
        TxDataHS = 32'hDEADBEEF;
        #30;
        
        // Apply reset
        rst = 1;
        #20;
        rst = 0;
        #20;
        
        // Test Case 3: No HS enable
        $display("Test Case 3: No HS enable");
        hs_en = 0;
        TxDataTransferEnHS = 1;
        TxWordValidHS = 1;
        TxDataHS = 32'h12345678;
        #100;
        
        // Test Case 4: Timer not done
        $display("Test Case 4: Timer not done");
        hs_en = 1;
        time_done = 0;
        #50;
        time_done = 1;
        #10;
        time_done = 0;
        
        // Complete the sequence
        Serial_End = 1;
        #20;
        Serial_End = 0;
        TxWordValidHS = 1;
        TxDataHS = 32'hF0F0F0F0;
        #40;
        TxWordValidHS = 0;
        #100;
        
        $display("All test cases completed");
        $finish;
    end
    
    // Monitor outputs
    always @(posedge clk) begin
        $display("Time: %0t ns | State: %d | HS_prll_data: %h | Serial_Valid: %b | TxRdHS: %b", 
                 $time, uut.current_state, HS_prll_data, Serial_Valid, TxRdHS);
    end
    
    // Check for specific conditions
    always @(posedge clk) begin
        if (Serial_Valid && TxRdHS) begin
            $display("Data transfer active: HS_prll_data = %h", HS_prll_data);
        end
        
        if (valid_done) begin
            $display("Valid done signal asserted");
        end
        
        if (Trail) begin
            $display("Trail signal asserted");
        end
    end
    
    // Waveform dump for debugging
    initial begin
        $dumpfile("Data_HS_CTL.vcd");
        $dumpvars(0, tb_Data_HS_CTL);
    end
endmodule