module config_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    input [1:0] mode,  // 00-Fixed 01-RR 10-Prio 11-Random
    input [WIDTH-1:0] cfg_reg,
    output reg [WIDTH-1:0] grant_o
);
reg [$clog2(WIDTH)-1:0] ptr;
reg [WIDTH-1:0] mask;
integer i;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ptr <= 0;
        grant_o <= 0;
    end else begin
        case(mode)
            2'b00: grant_o <= req_i & (~req_i + 1);       // Fixed
            2'b01: begin                                  // Round Robin
                grant_o <= 0;
                for(i=0; i<WIDTH; i=i+1) begin
                    if(req_i[(ptr+i)%WIDTH] && (grant_o == 0)) begin
                        grant_o <= 1 << ((ptr+i)%WIDTH);
                        ptr <= (ptr+i+1)%WIDTH;
                    end
                end
            end
            2'b10: grant_o <= cfg_reg & req_i;            // Priority
            2'b11: begin                                  // Random
                // Replace random with a simple pattern
                mask <= {mask[WIDTH-2:0], mask[WIDTH-1]};
                grant_o <= req_i & mask;
            end
        endcase
    end
end

// Initialize mask for pseudo-random generation  
initial mask = {{(WIDTH-1){1'b0}}, 1'b1};
endmodule