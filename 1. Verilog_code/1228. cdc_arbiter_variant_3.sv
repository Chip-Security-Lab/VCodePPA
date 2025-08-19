//SystemVerilog
module cdc_arbiter #(
    parameter WIDTH = 4
) (
    input                  clk_a,
    input                  clk_b,
    input                  rst_n,
    input  [WIDTH-1:0]     req_a,
    output [WIDTH-1:0]     grant_b
);
    // Synchronization registers for CDC
    reg  [WIDTH-1:0] sync0_reg;
    reg  [WIDTH-1:0] sync1_reg;
    reg  [WIDTH-1:0] grant_b_reg;
    wire [WIDTH-1:0] prioritized_req;
    
    // CDC Stage 1: First synchronization register
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            sync0_reg <= {WIDTH{1'b0}};
        end else begin
            sync0_reg <= req_a;
        end
    end
    
    // CDC Stage 2: Second synchronization register
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            sync1_reg <= {WIDTH{1'b0}};
        end else begin
            sync1_reg <= sync0_reg;
        end
    end

    // Optimized priority encoder implementation
    generate
        if (WIDTH <= 4) begin : small_width
            // Direct implementation for small widths - find lowest set bit
            assign prioritized_req = sync1_reg & (~sync1_reg + 1'b1);
        end else begin : large_width
            // Optimized implementation using cascaded priority logic
            reg [WIDTH-1:0] priority_mask;
            
            // Priority encoding logic
            always @(*) begin
                priority_mask = {WIDTH{1'b0}};
                find_first_req(sync1_reg, priority_mask);
            end
            
            // Task to find first request with priority
            task find_first_req;
                input [WIDTH-1:0] req_vector;
                output [WIDTH-1:0] mask_vector;
                integer i;
                begin
                    for (i = 0; i < WIDTH; i = i + 1) begin
                        if (req_vector[i] && (mask_vector == {WIDTH{1'b0}})) begin
                            mask_vector[i] = 1'b1;
                        end
                    end
                end
            endtask
            
            assign prioritized_req = priority_mask;
        end
    endgenerate

    // Output register stage for improved timing
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            grant_b_reg <= {WIDTH{1'b0}};
        end else begin
            grant_b_reg <= prioritized_req;
        end
    end

    // Assign output
    assign grant_b = grant_b_reg;

endmodule