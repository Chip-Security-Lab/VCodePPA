//SystemVerilog
module multi_channel_parity #(
    parameter CHANNELS = 4,
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input [CHANNELS*WIDTH-1:0] ch_data,
    output reg [CHANNELS-1:0] ch_parity
);

    // Pipeline stage registers
    reg [CHANNELS*WIDTH-1:0] ch_data_reg;
    reg [CHANNELS-1:0] parity_temp;

    // Data path pipeline stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ch_data_reg <= 0;
        end else begin
            ch_data_reg <= ch_data;
        end
    end

    // Data path pipeline stage 2: Parity computation
    genvar i;
    generate
        for (i=0; i<CHANNELS; i=i+1) begin : gen_parity
            wire [WIDTH-1:0] data = ch_data_reg[i*WIDTH +: WIDTH];
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    parity_temp[i] <= 0;
                end else begin
                    parity_temp[i] <= ^data;
                end
            end
        end
    endgenerate

    // Data path pipeline stage 3: Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ch_parity <= 0;
        end else begin
            ch_parity <= parity_temp;
        end
    end

endmodule