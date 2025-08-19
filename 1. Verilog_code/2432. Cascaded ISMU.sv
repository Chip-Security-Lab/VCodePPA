module cascaded_ismu(
    input clk, reset,
    input [1:0] cascade_in,
    input [7:0] local_int,
    input [7:0] local_mask,
    output reg cascade_out,
    output reg [3:0] int_id
);
    reg [7:0] masked_int;
    reg [3:0] local_id;
    reg local_valid;
    
    always @(*) begin
        masked_int = local_int & ~local_mask;
        local_valid = |masked_int;
        local_id = masked_int[0] ? 4'd0 :
                   masked_int[1] ? 4'd1 :
                   masked_int[2] ? 4'd2 :
                   masked_int[3] ? 4'd3 :
                   masked_int[4] ? 4'd4 :
                   masked_int[5] ? 4'd5 :
                   masked_int[6] ? 4'd6 :
                   masked_int[7] ? 4'd7 : 4'd0;
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            int_id <= 4'd0;
            cascade_out <= 1'b0;
        end else begin
            cascade_out <= local_valid | |cascade_in;
            if (local_valid)
                int_id <= local_id;
            else if (cascade_in[0])
                int_id <= 4'd8;
            else if (cascade_in[1])
                int_id <= 4'd9;
        end
    end
endmodule