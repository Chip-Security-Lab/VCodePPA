//SystemVerilog
module signed_to_unsigned #(parameter WIDTH=16)(
    input wire                   clk,
    input wire                   rst_n,
    input wire [WIDTH-1:0]       signed_in,
    output reg [WIDTH-1:0]       unsigned_out,
    output reg                   overflow
);

    // Pipeline stage 1: Register input and sign bit
    reg [WIDTH-1:0]              pipe1_signed_in;
    reg                          pipe1_sign_bit;

    // Pipeline stage 2: Register sign bit and pass data
    reg [WIDTH-1:0]              pipe2_signed_in;
    reg                          pipe2_sign_bit;

    // Pipeline stage 3: Conversion logic outputs
    reg [WIDTH-1:0]              pipe3_unsigned_out;
    reg                          pipe3_overflow;

    // Stage 1: Input Registering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe1_signed_in <= {WIDTH{1'b0}};
            pipe1_sign_bit  <= 1'b0;
        end else begin
            pipe1_signed_in <= signed_in;
            pipe1_sign_bit  <= signed_in[WIDTH-1];
        end
    end

    // Stage 2: Pass-through registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe2_signed_in <= {WIDTH{1'b0}};
            pipe2_sign_bit  <= 1'b0;
        end else begin
            pipe2_signed_in <= pipe1_signed_in;
            pipe2_sign_bit  <= pipe1_sign_bit;
        end
    end

    // Stage 3: Conversion and register outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe3_unsigned_out <= {WIDTH{1'b0}};
            pipe3_overflow     <= 1'b0;
        end else begin
            pipe3_overflow     <= pipe2_sign_bit;
            pipe3_unsigned_out <= pipe2_sign_bit ? {WIDTH{1'b0}} : pipe2_signed_in;
        end
    end

    // Stage 4: Output Registering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            unsigned_out <= {WIDTH{1'b0}};
            overflow     <= 1'b0;
        end else begin
            unsigned_out <= pipe3_unsigned_out;
            overflow     <= pipe3_overflow;
        end
    end

endmodule