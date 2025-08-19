module int_ctrl_rr #(
    parameter WIDTH = 4
)(
    input clk, en,
    input [WIDTH-1:0] req,
    output reg [WIDTH-1:0] grant,
    output reg valid
);
    reg [2:0] rr_ptr;  // Using 3 bits is enough for WIDTH=4
    integer i;
    
    always @(posedge clk) begin
        if(en) begin
            grant <= {WIDTH{1'b0}};
            valid <= |req;
            
            if(|req) begin
                for(i = 0; i < WIDTH; i = i + 1) begin
                    if(req[(rr_ptr + i) % WIDTH]) begin
                        grant <= 1'b1 << ((rr_ptr + i) % WIDTH);
                        rr_ptr <= ((rr_ptr + i) % WIDTH) + 1'b1;
                        break;
                    end
                end
            end
        end
    end
endmodule