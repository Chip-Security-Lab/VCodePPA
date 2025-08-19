//SystemVerilog
module arith_right_shifter (
    input CLK, RST_n,
    input [15:0] DATA_IN,
    input SHIFT,
    input VALID_IN,
    output [15:0] DATA_OUT,
    output VALID_OUT
);
    // Internal connections between stages
    wire [15:0] data_stage1;
    wire shift_stage1;
    wire valid_stage1;
    
    wire [15:0] data_stage2;
    wire valid_stage2;
    
    // Stage 1: Input Registration
    input_stage input_reg (
        .clk(CLK),
        .rst_n(RST_n),
        .data_in(DATA_IN),
        .shift_in(SHIFT),
        .valid_in(VALID_IN),
        .data_out(data_stage1),
        .shift_out(shift_stage1),
        .valid_out(valid_stage1)
    );
    
    // Stage 2: Shift Operation
    shift_stage shift_op (
        .clk(CLK),
        .rst_n(RST_n),
        .data_in(data_stage1),
        .shift_in(shift_stage1),
        .valid_in(valid_stage1),
        .data_out(data_stage2),
        .valid_out(valid_stage2)
    );
    
    // Stage 3: Output Registration
    output_stage output_reg (
        .clk(CLK),
        .rst_n(RST_n),
        .data_in(data_stage2),
        .valid_in(valid_stage2),
        .data_out(DATA_OUT),
        .valid_out(VALID_OUT)
    );
endmodule

// Stage 1: Input Registration Module
module input_stage (
    input clk,
    input rst_n,
    input [15:0] data_in,
    input shift_in,
    input valid_in,
    output reg [15:0] data_out,
    output reg shift_out,
    output reg valid_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 16'h0000;
            shift_out <= 1'b0;
            valid_out <= 1'b0;
        end
        else begin
            data_out <= data_in;
            shift_out <= shift_in;
            valid_out <= valid_in;
        end
    end
endmodule

// Stage 2: Shift Operation Module
module shift_stage (
    input clk,
    input rst_n,
    input [15:0] data_in,
    input shift_in,
    input valid_in,
    output reg [15:0] data_out,
    output reg valid_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 16'h0000;
            valid_out <= 1'b0;
        end
        else begin
            if (valid_in) begin
                if (shift_in)
                    data_out <= {data_in[15], data_in[15:1]}; // Sign extension
                else
                    data_out <= data_in;
                
                valid_out <= valid_in;
            end
        end
    end
endmodule

// Stage 3: Output Registration Module
module output_stage (
    input clk,
    input rst_n,
    input [15:0] data_in,
    input valid_in,
    output reg [15:0] data_out,
    output reg valid_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 16'h0000;
            valid_out <= 1'b0;
        end
        else begin
            data_out <= data_in;
            valid_out <= valid_in;
        end
    end
endmodule