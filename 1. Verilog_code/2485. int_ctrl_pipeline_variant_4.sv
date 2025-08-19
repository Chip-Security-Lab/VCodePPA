//SystemVerilog
module int_ctrl_pipeline #(
    parameter DW = 8
)(
    input clk, en,
    input [DW-1:0] req_in,
    output reg [DW-1:0] req_q,
    output reg [3:0] curr_pri
);
    // Register the inputs first to reduce input to register delay
    reg [DW-1:0] req_in_r;
    
    always @(posedge clk) begin
        if(en) begin
            req_in_r <= req_in;
        end
    end
    
    // Pre-compute the OR of requests (moved after register)
    wire [DW-1:0] combined_req;
    assign combined_req = req_in_r | req_q;
    
    // Optimized priority encoder with balanced paths
    function [3:0] find_highest_pri;
        input [DW-1:0] req;
        reg [3:0] pri;
        reg [3:0] found;
        begin
            // Default priority
            pri = 4'd0;
            found = 4'd0;
            
            // Check highest 4 bits (if DW >= 4)
            if(req[7] && DW > 7) begin pri = 4'd7; found = 4'd1; end
            else if(req[6] && DW > 6) begin pri = 4'd6; found = 4'd1; end
            else if(req[5] && DW > 5) begin pri = 4'd5; found = 4'd1; end
            else if(req[4] && DW > 4) begin pri = 4'd4; found = 4'd1; end
            
            // Check lower 4 bits (only if no higher priority found)
            if(found == 4'd0) begin
                if(req[3] && DW > 3) pri = 4'd3;
                else if(req[2] && DW > 2) pri = 4'd2;
                else if(req[1] && DW > 1) pri = 4'd1;
                else if(req[0]) pri = 4'd0;
            end
            
            find_highest_pri = pri;
        end
    endfunction
    
    // Pre-compute priority value
    wire [3:0] new_pri;
    assign new_pri = find_highest_pri(combined_req);
    
    // Pre-compute mask for clearing granted request
    wire [DW-1:0] clear_mask;
    assign clear_mask = {{(DW-1){1'b1}}, 1'b0} << new_pri;
    
    // Split the computation for better timing balance
    reg [3:0] new_pri_r;
    reg [DW-1:0] clear_mask_r;
    
    always @(posedge clk) begin
        if(en) begin
            new_pri_r <= new_pri;
            clear_mask_r <= clear_mask;
        end
    end
    
    // Final output logic with reduced path length
    always @(posedge clk) begin
        if(en) begin
            req_q <= combined_req & clear_mask_r;
            curr_pri <= new_pri_r;
        end
    end
endmodule