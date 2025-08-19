//SystemVerilog
module therm_decoder_pipelined (
    input clock,
    input reset_n,
    input [2:0] binary_in,
    input valid_in,
    output reg [7:0] therm_out,
    output reg valid_out
);

    // Stage 1 signals
    wire [2:0] binary_stage1;
    wire [7:0] therm_stage1;
    wire valid_stage1;
    
    // Stage 2 signals
    wire [7:0] therm_stage2;
    wire valid_stage2;

    // Stage 1: Binary to thermometer conversion
    therm_conversion_stage1 stage1 (
        .clock(clock),
        .reset_n(reset_n),
        .binary_in(binary_in),
        .valid_in(valid_in),
        .binary_out(binary_stage1),
        .therm_out(therm_stage1),
        .valid_out(valid_stage1)
    );

    // Stage 2: Pipeline register
    pipeline_reg_stage2 stage2 (
        .clock(clock),
        .reset_n(reset_n),
        .therm_in(therm_stage1),
        .valid_in(valid_stage1),
        .therm_out(therm_stage2),
        .valid_out(valid_stage2)
    );

    // Output stage
    output_stage stage3 (
        .clock(clock),
        .reset_n(reset_n),
        .therm_in(therm_stage2),
        .valid_in(valid_stage2),
        .therm_out(therm_out),
        .valid_out(valid_out)
    );

endmodule

module therm_conversion_stage1 (
    input clock,
    input reset_n,
    input [2:0] binary_in,
    input valid_in,
    output reg [2:0] binary_out,
    output reg [7:0] therm_out,
    output reg valid_out
);

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            binary_out <= 3'b0;
            therm_out <= 8'b0;
            valid_out <= 1'b0;
        end else begin
            binary_out <= binary_in;
            valid_out <= valid_in;
            
            therm_out[0] <= binary_in[0];
            therm_out[1] <= binary_in[0] | binary_in[1];
            therm_out[2] <= binary_in[0] | binary_in[1] | binary_in[2];
            therm_out[3] <= binary_in[1] | binary_in[2];
            therm_out[4] <= binary_in[1] & binary_in[2];
            therm_out[5] <= binary_in[2];
            therm_out[6] <= binary_in[2];
            therm_out[7] <= binary_in[2];
        end
    end

endmodule

module pipeline_reg_stage2 (
    input clock,
    input reset_n,
    input [7:0] therm_in,
    input valid_in,
    output reg [7:0] therm_out,
    output reg valid_out
);

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            therm_out <= 8'b0;
            valid_out <= 1'b0;
        end else begin
            therm_out <= therm_in;
            valid_out <= valid_in;
        end
    end

endmodule

module output_stage (
    input clock,
    input reset_n,
    input [7:0] therm_in,
    input valid_in,
    output reg [7:0] therm_out,
    output reg valid_out
);

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            therm_out <= 8'b0;
            valid_out <= 1'b0;
        end else begin
            therm_out <= therm_in;
            valid_out <= valid_in;
        end
    end

endmodule