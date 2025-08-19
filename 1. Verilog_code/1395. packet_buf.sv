module packet_buf #(parameter DW=8) (
    input clk, rst_n,
    input [DW-1:0] din,
    input din_valid,
    output reg [DW-1:0] dout,
    output reg pkt_valid
);
    reg [7:0] delimiter = 8'hFF;
    reg [2:0] state=0;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) state <= 0;
        else case(state)
            0: if(din_valid && (din == delimiter)) state <= 1;
            1: begin
                dout <= din;
                pkt_valid <= 1;
                state <= 2;
            end
            2: if(!din_valid) state <= 0;
        endcase
    end
endmodule
