//SystemVerilog
module hamming_encoder #(
    parameter DATA_WIDTH = 4,
    parameter ENCODED_WIDTH = 7
)(
    input clk,
    input rst_n,
    input [DATA_WIDTH-1:0] data_in,
    output reg [ENCODED_WIDTH-1:0] encoded_out
);
    reg [DATA_WIDTH-1:0] data_buf;
    wire [2:0] parity_bits;
    
    // Compute parity bits in parallel
    assign parity_bits[0] = data_buf[0] ^ data_buf[1] ^ data_buf[3];
    assign parity_bits[1] = data_buf[0] ^ data_buf[2] ^ data_buf[3];
    assign parity_bits[2] = data_buf[1] ^ data_buf[2] ^ data_buf[3];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_buf <= {DATA_WIDTH{1'b0}};
            encoded_out <= {ENCODED_WIDTH{1'b0}};
        end else begin
            data_buf <= data_in;
            encoded_out <= {parity_bits[2], data_buf[3], data_buf[2], parity_bits[1], 
                          data_buf[1], parity_bits[0], data_buf[0]};
        end
    end
endmodule

module cdc_buffer #(
    parameter WIDTH = 7
)(
    input clk_in,
    input clk_out,
    input rst_n,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    reg [WIDTH-1:0] data_buf;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            data_buf <= {WIDTH{1'b0}};
        end else begin
            data_buf <= data_in;
        end
    end
    
    always @(posedge clk_out or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {WIDTH{1'b0}};
        end else begin
            data_out <= data_buf;
        end
    end
endmodule

module hamming_cdc(
    input clk_in,
    input clk_out,
    input rst_n,
    input [3:0] data_in,
    output [6:0] encoded_out
);
    wire [6:0] encoded_data;
    
    hamming_encoder #(
        .DATA_WIDTH(4),
        .ENCODED_WIDTH(7)
    ) encoder_inst (
        .clk(clk_in),
        .rst_n(rst_n),
        .data_in(data_in),
        .encoded_out(encoded_data)
    );
    
    cdc_buffer #(
        .WIDTH(7)
    ) cdc_inst (
        .clk_in(clk_in),
        .clk_out(clk_out),
        .rst_n(rst_n),
        .data_in(encoded_data),
        .data_out(encoded_out)
    );
endmodule