//SystemVerilog
module config_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    input [1:0] mode,  // 00-Fixed 01-RR 10-Prio 11-Random
    input [WIDTH-1:0] cfg_reg,
    output reg [WIDTH-1:0] grant_o
);
    reg [$clog2(WIDTH)-1:0] ptr;
    reg [WIDTH-1:0] mask;
    reg [WIDTH-1:0] req_reg;
    reg [1:0] mode_reg;
    reg [WIDTH-1:0] cfg_reg_reg;
    reg [WIDTH-1:0] fixed_grant, rr_grant, prio_grant, random_grant;
    integer i;
    
    // Register input signals to reduce input-to-register delay
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_reg <= 0;
            mode_reg <= 0;
            cfg_reg_reg <= 0;
        end else begin
            req_reg <= req_i;
            mode_reg <= mode;
            cfg_reg_reg <= cfg_reg;
        end
    end
    
    // Fixed priority calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fixed_grant <= 0;
        end else begin
            fixed_grant <= req_reg & (~req_reg + 1);
        end
    end
    
    // Round Robin logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ptr <= 0;
            rr_grant <= 0;
        end else begin
            rr_grant <= 0;
            for(i=0; i<WIDTH; i=i+1) begin
                if(req_reg[(ptr+i)%WIDTH] && (rr_grant == 0)) begin
                    rr_grant <= 1 << ((ptr+i)%WIDTH);
                    ptr <= (ptr+i+1)%WIDTH;
                end
            end
        end
    end
    
    // Priority mode calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prio_grant <= 0;
        end else begin
            prio_grant <= cfg_reg_reg & req_reg;
        end
    end
    
    // Random mode calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            random_grant <= 0;
            mask <= {{(WIDTH-1){1'b0}}, 1'b1};
        end else begin
            mask <= {mask[WIDTH-2:0], mask[WIDTH-1]};
            random_grant <= req_reg & mask;
        end
    end
    
    // Final output selection based on mode
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_o <= 0;
        end else begin
            case(mode_reg)
                2'b00: grant_o <= fixed_grant;
                2'b01: grant_o <= rr_grant;
                2'b10: grant_o <= prio_grant;
                2'b11: grant_o <= random_grant;
            endcase
        end
    end
endmodule