//SystemVerilog
module round_robin_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    reg [WIDTH-1:0] last_grant;
    reg [WIDTH-1:0] masked_req;
    reg [WIDTH-1:0] higher_pri_req;
    reg [WIDTH-1:0] lower_pri_req;
    reg [WIDTH-1:0] next_grant;
    wire [WIDTH-1:0] rotated_req;
    wire [WIDTH-1:0] rotated_grant;
    wire [$clog2(WIDTH)-1:0] last_grant_idx;

    // Calculate rotating mask based on previous grant
    assign last_grant_idx = get_idx(last_grant);
    
    // Split requests into two priority zones relative to the last grant
    always @(*) begin
        higher_pri_req = {req_i[WIDTH-1:0]} >> (last_grant_idx + 1);
        lower_pri_req = {req_i[WIDTH-1:0]} << (WIDTH - last_grant_idx - 1);
        masked_req = higher_pri_req | lower_pri_req;
        
        // Priority encoder implementation
        next_grant = get_highest_pri(masked_req);
        
        // If no requests, maintain zero output
        if (masked_req == {WIDTH{1'b0}})
            next_grant = {WIDTH{1'b0}};
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_o <= {WIDTH{1'b0}};
            last_grant <= {WIDTH{1'b0}};
        end else begin
            grant_o <= next_grant;
            if (next_grant != {WIDTH{1'b0}})
                last_grant <= next_grant;
        end
    end
    
    // Function to find the index of the first '1' in a one-hot encoded value
    function [$clog2(WIDTH)-1:0] get_idx;
        input [WIDTH-1:0] vec;
        reg [$clog2(WIDTH)-1:0] idx;
        begin
            idx = 0;
            for (int i = 0; i < WIDTH; i = i + 1)
                if (vec[i]) idx = i[$clog2(WIDTH)-1:0];
            get_idx = idx;
        end
    endfunction
    
    // Find highest priority (rightmost) bit set to 1
    function [WIDTH-1:0] get_highest_pri;
        input [WIDTH-1:0] req;
        reg [WIDTH-1:0] grant;
        begin
            grant = {WIDTH{1'b0}};
            for (int i = 0; i < WIDTH; i = i + 1) begin
                if (req[i] && grant == {WIDTH{1'b0}}) begin
                    grant[i] = 1'b1;
                end
            end
            get_highest_pri = grant;
        end
    endfunction
endmodule