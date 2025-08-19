//SystemVerilog
module int_ctrl_timeout #(
    parameter TIMEOUT = 8'hFF
)(
    input logic clk, rst,
    input logic [7:0] req_in,
    output logic [2:0] curr_grant,
    output logic timeout
);
    // Pipeline stage signals
    // Stage 1: Request processing
    logic [7:0] req_reg;
    logic req_valid;
    logic [2:0] priority_idx;
    
    // Stage 2: Grant generation
    logic [2:0] grant_idx;
    logic grant_update;
    
    // Stage 3: Timer control
    logic [7:0] timer_cnt;
    logic timer_reset;
    logic timer_max;
    
    // Request processing pipeline - Stage 1
    always_ff @(posedge clk) begin
        if (rst) begin
            req_reg <= 8'h0;
            req_valid <= 1'b0;
        end else begin
            req_reg <= req_in;
            req_valid <= |req_in;
        end
    end
    
    // Priority encoder with improved structure
    function automatic logic [2:0] find_highest_priority;
        input logic [7:0] req;
        logic [2:0] idx;
        begin
            if (req[0]) idx = 3'd0;
            else if (req[1]) idx = 3'd1;
            else if (req[2]) idx = 3'd2;
            else if (req[3]) idx = 3'd3;
            else if (req[4]) idx = 3'd4;
            else if (req[5]) idx = 3'd5;
            else if (req[6]) idx = 3'd6;
            else if (req[7]) idx = 3'd7;
            else idx = 3'd0;
            
            find_highest_priority = idx;
        end
    endfunction
    
    // Priority calculation - end of Stage 1
    always_ff @(posedge clk) begin
        if (rst) begin
            priority_idx <= 3'd0;
        end else if (!req_valid || !req_reg[curr_grant]) begin
            priority_idx <= find_highest_priority(req_reg);
        end
    end
    
    // Grant generation pipeline - Stage 2
    always_ff @(posedge clk) begin
        if (rst) begin
            grant_idx <= 3'd0;
            grant_update <= 1'b1;
        end else begin
            grant_idx <= priority_idx;
            grant_update <= !req_valid || !req_reg[curr_grant];
        end
    end
    
    // Current grant update - end of Stage 2
    always_ff @(posedge clk) begin
        if (rst) begin
            curr_grant <= 3'd0;
        end else if (grant_update) begin
            curr_grant <= grant_idx;
        end
    end
    
    // Timer control pipeline - Stage 3
    always_ff @(posedge clk) begin
        if (rst) begin
            timer_reset <= 1'b1;
        end else begin
            timer_reset <= !req_valid || !req_reg[curr_grant];
        end
    end
    
    // Timer counter with reset optimization
    always_ff @(posedge clk) begin
        if (rst || timer_reset) begin
            timer_cnt <= 8'h0;
            timer_max <= 1'b0;
        end else begin
            if (timer_cnt == TIMEOUT) begin
                timer_cnt <= 8'h0;
                timer_max <= 1'b1;
            end else begin
                timer_cnt <= timer_cnt + 8'h1;
                timer_max <= (timer_cnt == (TIMEOUT - 1));
            end
        end
    end
    
    // Timeout generation - final stage
    always_ff @(posedge clk) begin
        if (rst) begin
            timeout <= 1'b0;
        end else begin
            timeout <= timer_max;
        end
    end
    
endmodule