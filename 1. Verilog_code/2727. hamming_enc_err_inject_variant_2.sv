//SystemVerilog
// Hamming encoder submodule
module hamming_encoder(
    input clk, rst,
    input [3:0] data,
    output reg [6:0] encoded
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded <= 7'b0;
        end else begin
            encoded[0] <= data[0] ^ data[1] ^ data[3];
            encoded[1] <= data[0] ^ data[2] ^ data[3];
            encoded[2] <= data[0];
            encoded[3] <= data[1] ^ data[2] ^ data[3];
            encoded[4] <= data[1];
            encoded[5] <= data[2];
            encoded[6] <= data[3];
        end
    end

endmodule

// Error injection submodule
module error_injector(
    input clk, rst,
    input [6:0] data_in,
    input inject_error,
    input [2:0] error_pos,
    output reg [6:0] data_out
);

    wire [6:0] error_mask;
    assign error_mask = inject_error ? (7'b1 << error_pos) : 7'b0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= 7'b0;
        end else begin
            data_out <= data_in ^ error_mask;
        end
    end

endmodule

// Top level module
module hamming_enc_err_inject(
    input clk, rst,
    input [3:0] data,
    input inject_error,
    input [2:0] error_pos,
    output [6:0] encoded
);

    wire [6:0] normal_encoded;

    hamming_encoder encoder_inst(
        .clk(clk),
        .rst(rst),
        .data(data),
        .encoded(normal_encoded)
    );

    error_injector injector_inst(
        .clk(clk),
        .rst(rst),
        .data_in(normal_encoded),
        .inject_error(inject_error),
        .error_pos(error_pos),
        .data_out(encoded)
    );

endmodule