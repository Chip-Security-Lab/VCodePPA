//SystemVerilog
// Top-level module
module onehot_sync_decoder (
    input wire clock,
    input wire reset_n,
    input wire enable,
    input wire [2:0] addr_in,
    output wire [7:0] decode_out
);

    // Internal signals
    wire [2:0] addr_stage1;
    wire enable_stage1;
    wire [2:0] addr_stage2;
    wire enable_stage2;
    wire [7:0] decode_stage3;
    wire valid_stage3;
    wire [7:0] decode_stage4;
    wire valid_stage4;

    // Instantiate input sampling module
    input_sampling input_sampling_inst (
        .clock(clock),
        .reset_n(reset_n),
        .addr_in(addr_in),
        .enable(enable),
        .addr_out(addr_stage1),
        .enable_out(enable_stage1)
    );

    // Instantiate address buffering module
    address_buffer address_buffer_inst (
        .clock(clock),
        .reset_n(reset_n),
        .addr_in(addr_stage1),
        .enable_in(enable_stage1),
        .addr_out(addr_stage2),
        .enable_out(enable_stage2)
    );

    // Instantiate decoding computation module
    decode_computation decode_computation_inst (
        .clock(clock),
        .reset_n(reset_n),
        .addr_in(addr_stage2),
        .enable_in(enable_stage2),
        .decode_out(decode_stage3),
        .valid_out(valid_stage3)
    );

    // Instantiate decode buffer module
    decode_buffer decode_buffer_inst (
        .clock(clock),
        .reset_n(reset_n),
        .decode_in(decode_stage3),
        .valid_in(valid_stage3),
        .decode_out(decode_stage4),
        .valid_out(valid_stage4)
    );

    // Instantiate output generation module
    output_generation output_generation_inst (
        .clock(clock),
        .reset_n(reset_n),
        .decode_in(decode_stage4),
        .valid_in(valid_stage4),
        .decode_out(decode_out)
    );

endmodule

// Input sampling module
module input_sampling (
    input wire clock,
    input wire reset_n,
    input wire [2:0] addr_in,
    input wire enable,
    output reg [2:0] addr_out,
    output reg enable_out
);

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            addr_out <= 3'b0;
            enable_out <= 1'b0;
        end else begin
            addr_out <= addr_in;
            enable_out <= enable;
        end
    end

endmodule

// Address buffer module
module address_buffer (
    input wire clock,
    input wire reset_n,
    input wire [2:0] addr_in,
    input wire enable_in,
    output reg [2:0] addr_out,
    output reg enable_out
);

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            addr_out <= 3'b0;
            enable_out <= 1'b0;
        end else begin
            addr_out <= addr_in;
            enable_out <= enable_in;
        end
    end

endmodule

// Decode computation module
module decode_computation (
    input wire clock,
    input wire reset_n,
    input wire [2:0] addr_in,
    input wire enable_in,
    output reg [7:0] decode_out,
    output reg valid_out
);

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            decode_out <= 8'b0;
            valid_out <= 1'b0;
        end else begin
            if (enable_in) begin
                decode_out <= (8'b1 << addr_in);
                valid_out <= 1'b1;
            end else begin
                decode_out <= 8'b0;
                valid_out <= 1'b0;
            end
        end
    end

endmodule

// Decode buffer module
module decode_buffer (
    input wire clock,
    input wire reset_n,
    input wire [7:0] decode_in,
    input wire valid_in,
    output reg [7:0] decode_out,
    output reg valid_out
);

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            decode_out <= 8'b0;
            valid_out <= 1'b0;
        end else begin
            decode_out <= decode_in;
            valid_out <= valid_in;
        end
    end

endmodule

// Output generation module
module output_generation (
    input wire clock,
    input wire reset_n,
    input wire [7:0] decode_in,
    input wire valid_in,
    output reg [7:0] decode_out
);

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            decode_out <= 8'b0;
        end else begin
            decode_out <= valid_in ? decode_in : 8'b0;
        end
    end

endmodule