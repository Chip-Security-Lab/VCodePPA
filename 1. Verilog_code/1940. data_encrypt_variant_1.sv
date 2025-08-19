//SystemVerilog
module data_encrypt #(parameter DW=16) (
    input                  clk,
    input                  rst_n,
    input                  en,
    input  [DW-1:0]        din,
    input  [DW-1:0]        key,
    output reg [DW-1:0]    dout,
    output reg             dout_valid
);

    // Stage 1: Input capture and byte swap
    reg [DW-1:0]           din_swapped;
    reg [DW-1:0]           key_buffer;
    reg                    valid_buffer;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_swapped  <= {DW{1'b0}};
            key_buffer   <= {DW{1'b0}};
            valid_buffer <= 1'b0;
        end else if (en) begin
            din_swapped  <= {din[7:0], din[15:8]};
            key_buffer   <= key;
            valid_buffer <= 1'b1;
        end else begin
            valid_buffer <= 1'b0;
        end
    end

    // Stage 2: XOR operation and output register
    reg [DW-1:0]           encrypted_data;
    reg                    encrypted_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encrypted_data  <= {DW{1'b0}};
            encrypted_valid <= 1'b0;
        end else begin
            encrypted_data  <= din_swapped ^ key_buffer;
            encrypted_valid <= valid_buffer;
        end
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout       <= {DW{1'b0}};
            dout_valid <= 1'b0;
        end else begin
            dout       <= encrypted_data;
            dout_valid <= encrypted_valid;
        end
    end

endmodule