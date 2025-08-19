module int_ctrl_async_poll #(
    parameter DEPTH = 4
)(
    input [DEPTH-1:0] intr_in,
    output reg [DEPTH-1:0] poll_ptr,
    output reg ack
);
    integer i;
    
    always @* begin
        ack = |intr_in;
        poll_ptr = {DEPTH{1'b0}};
        
        for(i = 0; i < DEPTH; i = i + 1) begin
            if(intr_in[i]) begin
                poll_ptr[i] = 1'b1;
                break;
            end
        end
    end
endmodule