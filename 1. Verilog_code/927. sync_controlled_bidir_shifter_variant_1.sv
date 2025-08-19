//SystemVerilog
module sync_controlled_bidir_shifter (
    input                  clock,
    input                  resetn,
    input      [31:0]      data_in,
    input      [4:0]       shift_amount,
    input      [1:0]       mode,  // 00:left logical, 01:right logical
                                  // 10:left rotate, 11:right rotate
    output reg [31:0]      data_out,
    input                  valid_in,
    output reg             valid_out
);
    // Stage 1: Input registration and extended data preparation
    reg [31:0] data_stage1;
    reg [4:0]  shift_amount_stage1;
    reg [1:0]  mode_stage1;
    reg [63:0] extended_data_stage1;
    reg        valid_stage1;
    
    // Stage 2: Shift operation calculation
    reg [31:0] shift_result_stage2;
    reg        valid_stage2;
    
    // Stage 1: Register inputs and prepare extended data
    always @(posedge clock) begin
        if (!resetn) begin
            data_stage1 <= 32'h0;
            shift_amount_stage1 <= 5'h0;
            mode_stage1 <= 2'b00;
            extended_data_stage1 <= 64'h0;
            valid_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data_in;
            shift_amount_stage1 <= shift_amount;
            mode_stage1 <= mode;
            extended_data_stage1 <= {data_in, data_in};
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Perform shift operation based on mode
    always @(posedge clock) begin
        if (!resetn) begin
            shift_result_stage2 <= 32'h0;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            case(mode_stage1[1:0])
                2'b00: shift_result_stage2 <= data_stage1 << shift_amount_stage1;
                2'b01: shift_result_stage2 <= data_stage1 >> shift_amount_stage1;
                2'b10: shift_result_stage2 <= (extended_data_stage1 >> (32'd32 - {27'b0, shift_amount_stage1})) & 32'hFFFFFFFF;
                2'b11: shift_result_stage2 <= (extended_data_stage1 >> {27'b0, shift_amount_stage1}) & 32'hFFFFFFFF;
            endcase
        end
    end
    
    // Stage 3: Output registration
    always @(posedge clock) begin
        if (!resetn) begin
            data_out <= 32'h0;
            valid_out <= 1'b0;
        end else begin
            data_out <= shift_result_stage2;
            valid_out <= valid_stage2;
        end
    end
endmodule