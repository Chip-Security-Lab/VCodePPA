//SystemVerilog
// IEEE 1364-2005 Verilog standard
module power_efficient_shifter(
    input clk,
    input en,
    input [7:0] data_in,
    input [2:0] shift,
    output reg [7:0] data_out
);
    // Registered versions of high fanout signals for load balancing
    reg en_buf1, en_buf2, en_buf3, en_buf4;
    reg [2:0] shift_buf1, shift_buf2;
    
    // Register high fanout signals to reduce delay
    always @(posedge clk) begin
        en_buf1 <= en;
        en_buf2 <= en;
        en_buf3 <= en;
        en_buf4 <= en;
        shift_buf1 <= shift;
        shift_buf2 <= shift;
    end
    
    // Power gating signals with buffered control signals
    wire active_stage0, active_stage1, active_stage2;
    
    // Enable signals for power efficiency using buffered signals
    assign active_stage0 = en_buf1 & |shift_buf1;
    assign active_stage1 = en_buf2 & |shift_buf1[2:1];
    assign active_stage2 = en_buf3 & shift_buf2[2];
    
    // Intermediate signals for staged shifting
    reg [7:0] stage0_out;
    reg [7:0] stage1_out;
    reg [7:0] stage2_out;
    
    // Stage 0: 1-bit shift
    always @(posedge clk) begin
        if (en_buf1) begin
            if (active_stage0 && shift_buf1[0])
                stage0_out <= {data_in[6:0], 1'b0};
            else
                stage0_out <= data_in;
        end
    end
    
    // Stage 1: 2-bit shift
    always @(posedge clk) begin
        if (en_buf2) begin
            if (active_stage1 && shift_buf1[1])
                stage1_out <= {stage0_out[5:0], 2'b0};
            else
                stage1_out <= stage0_out;
        end
    end
    
    // Stage 2: 4-bit shift
    always @(posedge clk) begin
        if (en_buf3) begin
            if (active_stage2 && shift_buf2[2])
                stage2_out <= {stage1_out[3:0], 4'b0};
            else
                stage2_out <= stage1_out;
        end
    end
    
    // Final output assignment
    always @(posedge clk) begin
        if (en_buf4)
            data_out <= stage2_out;
    end
endmodule