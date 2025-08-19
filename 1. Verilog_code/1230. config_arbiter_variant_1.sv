//SystemVerilog
`define IEEE_1364_2005
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
    
    reg [WIDTH-1:0] fixed_grant;
    reg [WIDTH-1:0] rr_grant;
    reg [$clog2(WIDTH)-1:0] next_ptr;
    reg [WIDTH-1:0] prio_grant;
    reg [WIDTH-1:0] random_grant;
    reg [WIDTH-1:0] next_mask;
    
    // Fixed priority arbiter logic
    always @(*) begin
        fixed_grant = req_i & (~req_i + 1);
    end
    
    // Round Robin arbiter logic
    always @(*) begin
        rr_grant = {WIDTH{1'b0}};
        next_ptr = ptr;
        for(i=0; i<WIDTH; i=i+1) begin
            if(req_i[(ptr+i)%WIDTH] && (rr_grant == 0)) begin
                rr_grant = 1 << ((ptr+i)%WIDTH);
                next_ptr = (ptr+i+1)%WIDTH;
            end
        end
    end
    
    // Priority arbiter logic
    always @(*) begin
        prio_grant = cfg_reg & req_i;
    end
    
    // Random arbiter logic
    always @(*) begin
        next_mask = {mask[WIDTH-2:0], mask[WIDTH-1]};
        random_grant = req_i & mask;
    end
    
    // Mode selection and state update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ptr <= 0;
            mask <= {{(WIDTH-1){1'b0}}, 1'b1};
            grant_o <= 0;
        end else begin
            case(mode)
                2'b00: grant_o <= fixed_grant;    // Fixed
                2'b01: begin                      // Round Robin
                    grant_o <= rr_grant;
                    ptr <= next_ptr;
                end
                2'b10: grant_o <= prio_grant;     // Priority
                2'b11: begin                      // Random
                    grant_o <= random_grant;
                    mask <= next_mask;
                end
            endcase
        end
    end
endmodule