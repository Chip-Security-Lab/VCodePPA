module axi_stream_buf #(parameter DW=64) (
    input clk, rst_n,
    input tvalid_in, tready_out,
    output tvalid_out, tready_in,
    input [DW-1:0] tdata_in,
    output [DW-1:0] tdata_out
);
    reg [DW-1:0] buf_reg;
    reg buf_valid = 0;
    
    assign tready_in = ~buf_valid;
    assign tvalid_out = buf_valid;
    assign tdata_out = buf_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) buf_valid <= 0;
        else begin
            if(tvalid_in && tready_in) begin
                buf_reg <= tdata_in;
                buf_valid <= 1;
            end
            else if(tready_out && buf_valid)
                buf_valid <= 0;
        end
    end
endmodule
