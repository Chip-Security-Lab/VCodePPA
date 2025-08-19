//SystemVerilog
module ext_clk_monitor(
    input ext_clk,      // External clock to monitor
    input ref_clk,      // Reference clock
    input rst_n,        // Reset
    output reg clk_out, // Output clock
    output reg timeout  // Timeout indicator
);
    // Stage 1: Clock synchronization
    reg ext_clk_sync1, ext_clk_sync2;
    reg ext_clk_sync1_stage1;
    reg ext_clk_sync2_stage1;
    
    // Stage 2: Edge detection and watchdog counter
    reg edge_detected_stage2;
    reg [2:0] watchdog_stage2;
    reg [2:0] watchdog;
    reg timeout_stage2;
    
    // Stage 3: Output generation
    reg clk_out_stage3;
    
    // Pipeline stage valid signals
    reg stage1_valid, stage2_valid;
    
    // Carry-Skip Adder signals for watchdog counter
    wire [2:0] next_watchdog;
    wire [2:0] propagate;
    wire [2:0] generate_carry;
    wire [3:0] carry;
    
    // Stage 1: Input synchronization
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            ext_clk_sync1 <= 1'b0;
            ext_clk_sync2 <= 1'b0;
            ext_clk_sync1_stage1 <= 1'b0;
            ext_clk_sync2_stage1 <= 1'b0;
            stage1_valid <= 1'b0;
        end else begin
            ext_clk_sync1 <= ext_clk;
            ext_clk_sync2 <= ext_clk_sync1;
            
            // Register outputs for stage 1
            ext_clk_sync1_stage1 <= ext_clk_sync1;
            ext_clk_sync2_stage1 <= ext_clk_sync2;
            stage1_valid <= 1'b1;
        end
    end
    
    // Carry-Skip Adder implementation
    // Generate propagate signals
    assign propagate[0] = watchdog[0];
    assign propagate[1] = watchdog[1];
    assign propagate[2] = watchdog[2];
    
    // Generate carry signals
    assign generate_carry[0] = 1'b0;  // No carry generation for bit 0
    assign generate_carry[1] = watchdog[0] & 1'b1;  // Carry generated if bit 0 is 1
    assign generate_carry[2] = watchdog[1] & watchdog[0];  // Carry generated if bits 0,1 are 1
    
    // Carry chain
    assign carry[0] = 1'b1;  // Initial carry-in is 1 for incrementing
    assign carry[1] = generate_carry[0] | (propagate[0] & carry[0]);
    assign carry[2] = generate_carry[1] | (propagate[1] & carry[1]);
    assign carry[3] = generate_carry[2] | (propagate[2] & carry[2]);
    
    // Sum calculation
    assign next_watchdog[0] = watchdog[0] ^ carry[0];
    assign next_watchdog[1] = watchdog[1] ^ carry[1];
    assign next_watchdog[2] = watchdog[2] ^ carry[2];
    
    // Stage 2: Edge detection and watchdog logic
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            edge_detected_stage2 <= 1'b0;
            watchdog <= 3'd0;
            watchdog_stage2 <= 3'd0;
            timeout_stage2 <= 1'b0;
            stage2_valid <= 1'b0;
        end else if (stage1_valid) begin
            // Edge detection
            edge_detected_stage2 <= (ext_clk_sync2_stage1 != ext_clk_sync1_stage1);
            
            // Watchdog counter logic using carry-skip adder
            if (ext_clk_sync2_stage1 != ext_clk_sync1_stage1) begin
                watchdog <= 3'd0;
                timeout_stage2 <= 1'b0;
            end else if (watchdog < 3'd7) begin
                watchdog <= next_watchdog;
                timeout_stage2 <= 1'b0;
            end else begin
                timeout_stage2 <= 1'b1;
            end
            
            // Register outputs for stage 2
            watchdog_stage2 <= watchdog;
            stage2_valid <= 1'b1;
        end else begin
            stage2_valid <= 1'b0;
        end
    end
    
    // Stage 3: Output generation
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_out <= 1'b0;
            timeout <= 1'b0;
        end else if (stage2_valid) begin
            if (edge_detected_stage2) begin
                clk_out <= ext_clk_sync2_stage1;
            end
            timeout <= timeout_stage2;
        end
    end
endmodule