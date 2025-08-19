module multicycle_sync #(parameter WIDTH = 24, CYCLES = 2) (
    input wire fast_clk, slow_clk, rst_n,
    input wire [WIDTH-1:0] data_fast,
    input wire update_fast,
    output reg [WIDTH-1:0] data_slow
);
    reg [WIDTH-1:0] data_reg;
    reg update_toggle;
    reg [2:0] update_sync;
    reg update_slow;
    reg [$clog2(CYCLES):0] cycle_count;
    
    // Fast clock domain toggle
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            update_toggle <= 1'b0;
            data_reg <= {WIDTH{1'b0}};
        end else if (update_fast) begin
            update_toggle <= ~update_toggle;
            data_reg <= data_fast;
        end
    end
    
    // Slow clock domain sync and multicycle wait
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            update_sync <= 3'b0;
            update_slow <= 1'b0;
            cycle_count <= 0;
            data_slow <= {WIDTH{1'b0}};
        end else begin
            update_sync <= {update_sync[1:0], update_toggle};
            
            if (update_sync[2] != update_sync[1])
                update_slow <= 1'b1;
                
            if (update_slow) begin
                if (cycle_count == CYCLES-1) begin
                    cycle_count <= 0;
                    update_slow <= 1'b0;
                    data_slow <= data_reg;
                end else begin
                    cycle_count <= cycle_count + 1'b1;
                end
            end
        end
    end
endmodule