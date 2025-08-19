module dist_icmu (
    input wire core_clk,
    input wire [3:0] local_int_req,
    input wire [1:0] remote_int_req,
    input wire [31:0] cpu_ctx,
    output reg [31:0] saved_ctx,
    output reg [2:0] int_src,
    output reg int_valid,
    output reg local_ack,
    output reg [1:0] remote_ack
);
    localparam LOCAL_BASE = 0;
    localparam REMOTE_BASE = 4;
    
    reg [5:0] pending = 6'b0;
    reg [5:0] active = 6'b0;
    reg handling = 1'b0;
    
    // Combined interrupt sources
    always @(posedge core_clk) begin
        pending[3:0] <= pending[3:0] | local_int_req;
        pending[5:4] <= pending[5:4] | remote_int_req;
        
        if (!handling && |pending) begin
            if (|pending[5:4]) begin
                // Handle remote interrupts first (higher priority)
                int_src <= get_src(pending[5:4], REMOTE_BASE);
                remote_ack <= pending[5:4];
                local_ack <= 1'b0;
                active[5:4] <= pending[5:4];
                pending[5:4] <= 2'b00;
            end else begin
                // Handle local interrupts
                int_src <= get_src(pending[3:0], LOCAL_BASE);
                local_ack <= 1'b1 << int_src[1:0];
                remote_ack <= 2'b00;
                active[3:0] <= 1'b1 << int_src[1:0];
                pending[int_src[1:0]] <= 1'b0;
            end
            
            int_valid <= 1'b1;
            saved_ctx <= cpu_ctx;
            handling <= 1'b1;
        end else if (handling) begin
            remote_ack <= 2'b00;
            local_ack <= 1'b0;
            active <= 6'b0;
            int_valid <= 1'b0;
            handling <= 1'b0;
        end
    end
    
    function [2:0] get_src;
        input [3:0] src_bits;
        input [2:0] base;
        begin
            casez(src_bits)
                4'b???1: get_src = base;
                4'b??10: get_src = base + 1;
                4'b?100: get_src = base + 2;
                4'b1000: get_src = base + 3;
                default: get_src = base;
            endcase
        end
    endfunction
endmodule