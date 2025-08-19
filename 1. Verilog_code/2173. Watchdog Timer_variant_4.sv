//SystemVerilog
//IEEE 1364-2005 Verilog标准
module watchdog_timer #(parameter WIDTH = 24)(
    input clk_i, rst_ni, wdt_en_i, feed_i,
    input [WIDTH-1:0] timeout_i,
    output reg timeout_o
);
    // Pipeline stage 1: Edge detection
    reg feed_d, feed_d_stage1;
    reg wdt_en_stage1;
    reg [WIDTH-1:0] timeout_stage1;
    wire feed_edge_stage1;
    
    // Pipeline stage 2: Counter management
    reg [WIDTH-1:0] counter;
    reg [WIDTH-1:0] counter_stage2;
    reg feed_edge_stage2;
    reg wdt_en_stage2;
    reg [WIDTH-1:0] timeout_stage2;
    
    // Pipeline stage 3: Timeout detection using carry-lookahead borrow subtraction
    reg counter_timeout_stage3;
    reg wdt_en_stage3;
    
    // Borrow generation and propagation signals
    wire [WIDTH-1:0] borrow_generate;
    wire [WIDTH-1:0] borrow_propagate;
    wire [WIDTH:0] borrow;
    
    // Stage 1: Edge detection
    always @(posedge clk_i) begin
        if (!rst_ni) begin
            feed_d <= 1'b0;
            feed_d_stage1 <= 1'b0;
            wdt_en_stage1 <= 1'b0;
            timeout_stage1 <= {WIDTH{1'b0}};
        end else begin
            feed_d <= feed_i;
            feed_d_stage1 <= feed_d;
            wdt_en_stage1 <= wdt_en_i;
            timeout_stage1 <= timeout_i;
        end
    end
    
    assign feed_edge_stage1 = feed_i & ~feed_d;
    
    // Stage 2: Counter management
    always @(posedge clk_i) begin
        if (!rst_ni) begin
            counter <= {WIDTH{1'b0}};
            counter_stage2 <= {WIDTH{1'b0}};
            feed_edge_stage2 <= 1'b0;
            wdt_en_stage2 <= 1'b0;
            timeout_stage2 <= {WIDTH{1'b0}};
        end else begin
            feed_edge_stage2 <= feed_edge_stage1;
            wdt_en_stage2 <= wdt_en_stage1;
            timeout_stage2 <= timeout_stage1;
            
            if (wdt_en_stage1) begin
                if (feed_edge_stage1) begin
                    counter <= {WIDTH{1'b0}};
                end else begin
                    counter <= counter + 1'b1;
                end
            end
            
            counter_stage2 <= counter;
        end
    end
    
    // Carry-lookahead borrow subtractor for timeout detection
    // Generate and propagate signals for borrow lookahead
    assign borrow_generate = ~counter_stage2 & timeout_stage2;
    assign borrow_propagate = ~counter_stage2 | timeout_stage2;
    
    // Compute borrows using lookahead method (8-bit blocks)
    assign borrow[0] = 1'b0; // No initial borrow
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 8) begin : borrow_lookahead_blocks
            if (i + 8 <= WIDTH) begin : full_block
                // 8-bit lookahead block
                assign borrow[i+1] = borrow_generate[i] | (borrow_propagate[i] & borrow[i]);
                assign borrow[i+2] = borrow_generate[i+1] | (borrow_propagate[i+1] & borrow[i+1]);
                assign borrow[i+3] = borrow_generate[i+2] | (borrow_propagate[i+2] & borrow[i+2]);
                assign borrow[i+4] = borrow_generate[i+3] | (borrow_propagate[i+3] & borrow[i+3]);
                assign borrow[i+5] = borrow_generate[i+4] | (borrow_propagate[i+4] & borrow[i+4]);
                assign borrow[i+6] = borrow_generate[i+5] | (borrow_propagate[i+5] & borrow[i+5]);
                assign borrow[i+7] = borrow_generate[i+6] | (borrow_propagate[i+6] & borrow[i+6]);
                assign borrow[i+8] = borrow_generate[i+7] | (borrow_propagate[i+7] & borrow[i+7]);
            end else begin : partial_block
                // Handle remaining bits (less than 8)
                for (i = i; i < WIDTH; i = i + 1) begin : remaining_bits
                    assign borrow[i+1] = borrow_generate[i] | (borrow_propagate[i] & borrow[i]);
                end
            end
        end
    endgenerate
    
    wire is_less_than = borrow[WIDTH]; // Final borrow indicates counter < timeout
    
    // Stage 3: Timeout detection
    always @(posedge clk_i) begin
        if (!rst_ni) begin
            counter_timeout_stage3 <= 1'b0;
            wdt_en_stage3 <= 1'b0;
            timeout_o <= 1'b0;
        end else begin
            counter_timeout_stage3 <= ~is_less_than; // Equivalent to counter_stage2 >= timeout_stage2
            wdt_en_stage3 <= wdt_en_stage2;
            
            if (wdt_en_stage3 && counter_timeout_stage3) begin
                timeout_o <= 1'b1;
            end else if (!wdt_en_stage3) begin
                timeout_o <= 1'b0;
            end
        end
    end
endmodule