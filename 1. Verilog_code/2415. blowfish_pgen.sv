module blowfish_pgen (
    input clk, init,
    input [31:0] key_segment,
    output reg [31:0] p_box_out
);
    reg [31:0] p_box [0:17];
    integer i;
    
    always @(posedge clk) begin
        if (init) begin
            for(i=0; i<18; i=i+1)
                p_box[i] <= 32'hB7E15163 + i*32'h9E3779B9;
        end else begin
            p_box[0] <= p_box[0] ^ key_segment;
            for(i=1; i<18; i=i+1)
                p_box[i] <= p_box[i] + (p_box[i-1] << 3);
            p_box_out <= p_box[17];
        end
    end
endmodule
