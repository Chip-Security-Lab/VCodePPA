//SystemVerilog
module multicycle_sync #(parameter WIDTH = 24, CYCLES = 2) (
    input wire fast_clk,
    input wire slow_clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_fast,
    input wire update_fast,
    output reg [WIDTH-1:0] data_slow
);

    reg [WIDTH-1:0] data_reg_fast;
    reg update_toggle_fast;
    reg [2:0] update_toggle_sync;
    reg update_slow_flag;
    reg [$clog2(CYCLES):0] cycle_counter;
    
    // Pipeline register for data crossing to slow domain
    reg [WIDTH-1:0] data_reg_pipeline_1;
    reg [WIDTH-1:0] data_reg_pipeline_2;

    // Fast clock domain toggle logic
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            update_toggle_fast <= 1'b0;
            data_reg_fast <= {WIDTH{1'b0}};
        end else if (update_fast) begin
            update_toggle_fast <= ~update_toggle_fast;
            data_reg_fast <= data_fast;
        end
    end

    // First stage pipeline register - capture data_reg_fast
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg_pipeline_1 <= {WIDTH{1'b0}};
        end else begin
            data_reg_pipeline_1 <= data_reg_fast;
        end
    end

    // Second stage pipeline register - further pipeline to cut critical path
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg_pipeline_2 <= {WIDTH{1'b0}};
        end else begin
            data_reg_pipeline_2 <= data_reg_pipeline_1;
        end
    end

    // Slow clock domain sync and multicycle wait, with pipelined data path
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            update_toggle_sync <= 3'b0;
            update_slow_flag <= 1'b0;
            cycle_counter <= 0;
            data_slow <= {WIDTH{1'b0}};
        end else begin
            update_toggle_sync <= {update_toggle_sync[1:0], update_toggle_fast};
            case ({update_slow_flag, (update_toggle_sync[2] != update_toggle_sync[1])})
                2'b00: begin
                    // No update_slow_flag, no edge detected
                end
                2'b01: begin
                    update_slow_flag <= 1'b1;
                end
                2'b10: begin
                    if (cycle_counter == CYCLES-1) begin
                        cycle_counter <= 0;
                        update_slow_flag <= 1'b0;
                        data_slow <= data_reg_pipeline_2;
                    end else begin
                        cycle_counter <= cycle_counter + 1'b1;
                    end
                end
                2'b11: begin
                    // Both update_slow_flag and edge detected (should not occur)
                end
            endcase
        end
    end

endmodule