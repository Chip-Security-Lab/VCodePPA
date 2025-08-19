//SystemVerilog
module hybrid_timing_shifter (
    input clk, 
    input rst_n,
    input en,
    input valid_in,
    output ready_out,
    input [7:0] din,
    input [2:0] shift,
    output [7:0] dout,
    output valid_out,
    input ready_in
);
    // Stage 1 registers
    reg [7:0] din_stage1;
    reg [2:0] shift_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg [7:0] result_stage2;
    reg valid_stage2;
    
    // Pipeline control signals
    wire stage1_ready;
    wire stage2_ready;
    
    // Ready-valid handshaking
    assign ready_out = stage1_ready;
    assign stage1_ready = !valid_stage1 || stage2_ready;
    assign stage2_ready = !valid_stage2 || ready_in;
    assign valid_out = valid_stage2;
    
    // Stage 1: Input registration and shift calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_stage1 <= 8'b0;
            shift_stage1 <= 3'b0;
            valid_stage1 <= 1'b0;
        end else if (en && stage1_ready) begin
            din_stage1 <= valid_in ? din : din_stage1;
            shift_stage1 <= valid_in ? shift : shift_stage1;
            valid_stage1 <= valid_in;
        end else if (stage1_ready && !valid_in) begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Stage 2: Perform shift operation and register result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
        end else if (en && stage2_ready) begin
            result_stage2 <= valid_stage1 ? (din_stage1 << shift_stage1) : result_stage2;
            valid_stage2 <= valid_stage1;
        end else if (stage2_ready && !valid_stage1) begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // Output assignment
    assign dout = result_stage2;
    
endmodule