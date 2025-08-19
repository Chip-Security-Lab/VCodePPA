//SystemVerilog
module updown_timer #(parameter WIDTH = 16)(
    input clk, rst_n, en, up_down,  // 1 = up, 0 = down
    input [WIDTH-1:0] load_val,
    input load_en,
    output reg [WIDTH-1:0] count,
    output reg overflow, underflow
);
    // Pre-register input signals to push registers forward
    reg en_r1, up_down_r1, load_en_r1;
    reg [WIDTH-1:0] load_val_r1;
    
    // Move input registers forward
    always @(posedge clk) begin
        if (!rst_n) begin
            en_r1 <= 1'b0;
            up_down_r1 <= 1'b0;
            load_en_r1 <= 1'b0;
            load_val_r1 <= {WIDTH{1'b0}};
        end
        else begin
            en_r1 <= en;
            up_down_r1 <= up_down;
            load_en_r1 <= load_en;
            load_val_r1 <= load_val;
        end
    end
    
    // Stage 2 control signals
    reg en_r2;
    reg up_down_r2;
    reg [WIDTH-1:0] count_r;
    
    // For wide counters, we can break the addition/subtraction into parts
    generate
        if (WIDTH >= 16) begin: wide_counter
            localparam HALF_WIDTH = WIDTH/2;
            
            reg [HALF_WIDTH-1:0] count_lower;
            reg [WIDTH-HALF_WIDTH-1:0] count_upper;
            reg carry;
            
            // First stage: handle lower bits - moved forward
            always @(posedge clk) begin
                if (!rst_n) begin
                    count_lower <= {HALF_WIDTH{1'b0}};
                    carry <= 1'b0;
                end
                else if (load_en_r1) begin  // Use registered load_en
                    count_lower <= load_val_r1[HALF_WIDTH-1:0];  // Use registered load_val
                    carry <= 1'b0;
                end
                else if (en_r1) begin  // Use registered enable
                    if (up_down_r1) begin  // Use registered direction
                        {carry, count_lower} <= count_lower + 1'b1;
                    end
                    else begin
                        {carry, count_lower} <= {1'b0, count_lower} - 1'b1;
                    end
                end
            end
            
            // Second stage: handle upper bits with carry - moved forward
            always @(posedge clk) begin
                if (!rst_n) begin
                    count_upper <= {(WIDTH-HALF_WIDTH){1'b0}};
                end
                else if (load_en_r1) begin  // Use registered load_en
                    count_upper <= load_val_r1[WIDTH-1:HALF_WIDTH];  // Use registered load_val
                end
                else if (en_r2) begin  // Use stage 2 registered enable
                    if (up_down_r2) begin  // Use stage 2 registered direction
                        count_upper <= count_upper + carry;
                    end
                    else begin
                        count_upper <= count_upper - carry;
                    end
                end
            end
            
            // Combine the parts for output
            always @(posedge clk) begin
                count <= {count_upper, count_lower};
            end
            
        end
        else begin: narrow_counter
            // For narrow counters, use registered inputs
            always @(posedge clk) begin
                if (!rst_n) count <= {WIDTH{1'b0}};
                else if (load_en_r1) count <= load_val_r1;  // Use registered inputs
                else if (en_r1) begin  // Use registered enable
                    if (up_down_r1) count <= count + 1'b1;  // Use registered direction
                    else count <= count - 1'b1;
                end
            end
        end
    endgenerate
    
    // Register control signals to stage 2 - moved forward from original
    always @(posedge clk) begin
        if (!rst_n) begin
            en_r2 <= 1'b0;
            up_down_r2 <= 1'b0;
            count_r <= {WIDTH{1'b0}};
        end
        else begin
            en_r2 <= en_r1;  // Chain from stage 1
            up_down_r2 <= up_down_r1;  // Chain from stage 1
            count_r <= count;
        end
    end
    
    // Pre-compute conditions to further push registers forward
    wire all_ones_comb = &count;
    wire all_zeros_comb = ~|count;
    
    // Pipeline the overflow/underflow detection logic - moved forward
    reg all_ones, all_zeros;
    always @(posedge clk) begin
        if (!rst_n) begin
            all_ones <= 1'b0;
            all_zeros <= 1'b0;
        end
        else begin
            all_ones <= all_ones_comb;  // Use pre-computed combinational logic
            all_zeros <= all_zeros_comb;  // Use pre-computed combinational logic
        end
    end
    
    // Final overflow/underflow determination - moved forward
    always @(posedge clk) begin
        if (!rst_n) begin
            overflow <= 1'b0;
            underflow <= 1'b0;
        end
        else begin
            overflow <= en_r2 & up_down_r2 & all_ones;  // Use stage 2 control signals
            underflow <= en_r2 & ~up_down_r2 & all_zeros;  // Use stage 2 control signals
        end
    end
endmodule