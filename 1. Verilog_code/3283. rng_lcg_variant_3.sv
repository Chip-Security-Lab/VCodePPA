//SystemVerilog
module rng_lcg_3_axi_stream (
    input            clk,
    input            rst_n,
    input            axi_stream_tready,
    output reg [7:0] axi_stream_tdata,
    output reg       axi_stream_tvalid,
    output reg       axi_stream_tlast
);
    parameter MULT = 8'd5;
    parameter INC  = 8'd1;

    reg [7:0] lcg_state;
    wire      handshake;

    assign handshake = axi_stream_tready & axi_stream_tvalid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lcg_state         <= 8'd7;
            axi_stream_tvalid <= 1'b0;
            axi_stream_tdata  <= 8'd0;
            axi_stream_tlast  <= 1'b0;
        end else begin
            if (axi_stream_tvalid) begin
                if (axi_stream_tready) begin
                    lcg_state         <= lcg_state * MULT + INC;
                    axi_stream_tdata  <= lcg_state * MULT + INC;
                    axi_stream_tvalid <= 1'b1;
                    axi_stream_tlast  <= 1'b0;
                end
            end else begin
                axi_stream_tdata  <= lcg_state;
                axi_stream_tvalid <= 1'b1;
                axi_stream_tlast  <= 1'b0;
            end
        end
    end
endmodule