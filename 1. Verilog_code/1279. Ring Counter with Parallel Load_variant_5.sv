//SystemVerilog
module loadable_ring_counter (
    input  wire        clock,
    input  wire        reset,
    input  wire        load,
    input  wire [3:0]  data_in,
    input  wire        valid_in,
    output wire        valid_out,
    output wire [3:0]  ring_out
);
    // Input capture stage registers
    reg        stage1_valid;
    reg        stage1_load;
    reg [3:0]  stage1_data;
    
    // Processing stage registers
    reg        stage2_valid;
    reg        stage2_load;
    reg [3:0]  stage2_data;
    
    // Output stage registers
    reg        valid_out_reg;
    reg [3:0]  ring_out_reg;
    
    // ===================================
    // Stage 1: Input Capture Pipeline
    // ===================================
    always @(posedge clock) begin
        if (reset) begin
            stage1_valid <= 1'b0;
            stage1_load  <= 1'b0;
            stage1_data  <= 4'b0000;
        end
        else begin
            stage1_valid <= valid_in;
            stage1_load  <= load;
            stage1_data  <= data_in;
        end
    end
    
    // ===================================
    // Stage 2: Processing Pipeline
    // ===================================
    always @(posedge clock) begin
        if (reset) begin
            stage2_valid <= 1'b0;
            stage2_load  <= 1'b0;
            stage2_data  <= 4'b0000;
        end
        else begin
            stage2_valid <= stage1_valid;
            stage2_load  <= stage1_load;
            stage2_data  <= stage1_data;
        end
    end
    
    // ===================================
    // Stage 3: Output Generation Pipeline
    // ===================================
    always @(posedge clock) begin
        if (reset) begin
            valid_out_reg <= 1'b0;
            ring_out_reg  <= 4'b0001; // Initial state of ring counter
        end
        else begin
            // Valid output control logic
            valid_out_reg <= stage2_valid;
            
            // Ring counter state update logic
            if (stage2_valid) begin
                if (stage2_load)
                    ring_out_reg <= stage2_data;
                else
                    ring_out_reg <= {ring_out_reg[2:0], ring_out_reg[3]};
            end
        end
    end
    
    // Drive output ports
    assign valid_out = valid_out_reg;
    assign ring_out  = ring_out_reg;
    
endmodule