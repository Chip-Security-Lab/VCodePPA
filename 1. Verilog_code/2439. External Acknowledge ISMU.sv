module ext_ack_ismu(
    input wire i_clk, i_rst,
    input wire [3:0] i_int,
    input wire [3:0] i_mask,
    input wire i_ext_ack,
    input wire [1:0] i_ack_id,
    output reg o_int_req,
    output reg [1:0] o_int_id
);
    reg [3:0] pending;
    wire [3:0] masked_int;
    
    assign masked_int = i_int & ~i_mask;
    
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            pending <= 4'h0;
            o_int_req <= 1'b0;
            o_int_id <= 2'h0;
        end else begin
            pending <= pending | masked_int;
            
            if (i_ext_ack)
                pending[i_ack_id] <= 1'b0;
                
            if (|pending) begin
                o_int_req <= 1'b1;
                o_int_id <= pending[0] ? 2'd0 : 
                           pending[1] ? 2'd1 : 
                           pending[2] ? 2'd2 : 2'd3;
            end else
                o_int_req <= 1'b0;
        end
    end
endmodule