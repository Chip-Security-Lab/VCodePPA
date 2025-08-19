//SystemVerilog
module shadow_reg_double_buf #(parameter WIDTH=16) (
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire swap,
    input wire [WIDTH-1:0] update_data,
    output wire [WIDTH-1:0] active_data,
    output wire valid_out
);
    // Stage 1 registers
    reg [WIDTH-1:0] buffer_reg_stage1;
    reg [WIDTH-1:0] active_data_stage1;
    reg valid_stage1;
    reg swap_stage1;
    
    // Stage 2 registers - intermediate stage for data preparation
    reg [WIDTH-1:0] buffer_reg_stage2;
    reg [WIDTH-1:0] active_data_stage2;
    reg valid_stage2;
    reg swap_stage2;
    
    // Stage 3 registers - swap decision stage
    reg [WIDTH-1:0] buffer_reg_stage3;
    reg [WIDTH-1:0] active_data_stage3;
    reg valid_stage3;
    reg swap_stage3;
    
    // Stage 4 registers - final output stage
    reg [WIDTH-1:0] buffer_reg_stage4;
    reg [WIDTH-1:0] active_data_stage4;
    reg valid_stage4;

    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_reg_stage1 <= {WIDTH{1'b0}};
            active_data_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
            swap_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= valid_in;
            swap_stage1 <= swap;
            
            if (valid_in) begin
                buffer_reg_stage1 <= update_data;
                active_data_stage1 <= active_data_stage4;
            end
        end
    end
    
    // Stage 2: Data preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_reg_stage2 <= {WIDTH{1'b0}};
            active_data_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
            swap_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            swap_stage2 <= swap_stage1;
            
            if (valid_stage1) begin
                // Pass through data to next stage
                buffer_reg_stage2 <= swap_stage1 ? buffer_reg_stage4 : buffer_reg_stage1;
                active_data_stage2 <= active_data_stage1;
            end
        end
    end
    
    // Stage 3: Swap decision preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_reg_stage3 <= {WIDTH{1'b0}};
            active_data_stage3 <= {WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
            swap_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
            swap_stage3 <= swap_stage2;
            
            if (valid_stage2) begin
                buffer_reg_stage3 <= buffer_reg_stage2;
                active_data_stage3 <= active_data_stage2;
            end
        end
    end
    
    // Stage 4: Final swap operation and output preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_reg_stage4 <= {WIDTH{1'b0}};
            active_data_stage4 <= {WIDTH{1'b0}};
            valid_stage4 <= 1'b0;
        end else begin
            valid_stage4 <= valid_stage3;
            
            if (valid_stage3) begin
                buffer_reg_stage4 <= buffer_reg_stage3;
                
                if (swap_stage3) begin
                    // Perform the swap
                    active_data_stage4 <= buffer_reg_stage3;
                end else begin
                    active_data_stage4 <= active_data_stage3;
                end
            end
        end
    end
    
    // Output assignments
    assign active_data = active_data_stage4;
    assign valid_out = valid_stage4;
    
endmodule