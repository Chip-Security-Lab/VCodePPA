//SystemVerilog
module wave8_ramp_down #(
    parameter WIDTH = 8,
    parameter STEP  = 1
)(
    input  wire                 clk,
    input  wire                 rst,
    input  wire                 valid_in,
    output wire                 ready_in,
    output wire [WIDTH-1:0]     wave_out,
    output wire                 valid_out,
    input  wire                 ready_out
);
    // Pipeline stage registers
    reg [WIDTH-1:0] wave_stage1;
    reg [WIDTH-1:0] wave_stage2;
    reg [WIDTH-1:0] wave_stage3;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2, valid_stage3;
    wire ready_stage1, ready_stage2, ready_stage3;
    
    // Computation split into multiple stages
    wire [WIDTH-1:0] sub_result_stage1 = {WIDTH{1'b1}} - (STEP >> 2);
    wire [WIDTH-1:0] sub_result_stage2 = wave_stage1 - (STEP >> 1);
    wire [WIDTH-1:0] sub_result_stage3 = wave_stage2 - (STEP >> 2);
    
    // Handshaking between stages
    assign ready_stage3 = ready_out || !valid_stage3;
    assign ready_stage2 = ready_stage3 || !valid_stage2;
    assign ready_stage1 = ready_stage2 || !valid_stage1;
    assign ready_in = ready_stage1 || !valid_in;
    
    // First pipeline stage
    always @(posedge clk) begin
        if (rst) begin
            wave_stage1 <= {WIDTH{1'b1}};
            valid_stage1 <= 1'b0;
        end else if (ready_stage1) begin
            if (valid_in) begin
                wave_stage1 <= sub_result_stage1;
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Second pipeline stage
    always @(posedge clk) begin
        if (rst) begin
            wave_stage2 <= {WIDTH{1'b1}};
            valid_stage2 <= 1'b0;
        end else if (ready_stage2) begin
            if (valid_stage1) begin
                wave_stage2 <= sub_result_stage2;
                valid_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // Third pipeline stage
    always @(posedge clk) begin
        if (rst) begin
            wave_stage3 <= {WIDTH{1'b1}};
            valid_stage3 <= 1'b0;
        end else if (ready_stage3) begin
            if (valid_stage2) begin
                wave_stage3 <= sub_result_stage3;
                valid_stage3 <= 1'b1;
            end else begin
                valid_stage3 <= 1'b0;
            end
        end
    end
    
    // Output assignments
    assign wave_out = wave_stage3;
    assign valid_out = valid_stage3;
    
endmodule