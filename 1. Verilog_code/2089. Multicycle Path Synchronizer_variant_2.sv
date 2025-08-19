//SystemVerilog
module multicycle_sync #(parameter WIDTH = 24, CYCLES = 2) (
    input wire fast_clk,
    input wire slow_clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_fast,
    input wire update_fast,
    output reg [WIDTH-1:0] data_slow
);
    // Fast domain registers
    reg [WIDTH-1:0] data_reg_fast;
    reg update_toggle_fast;

    // Fanout buffer for slow_clk in slow domain
    wire slow_clk_buf1, slow_clk_buf2;
    reg slow_clk_buf_reg1, slow_clk_buf_reg2;
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            slow_clk_buf_reg1 <= 1'b0;
            slow_clk_buf_reg2 <= 1'b0;
        end else begin
            slow_clk_buf_reg1 <= 1'b1;
            slow_clk_buf_reg2 <= 1'b1;
        end
    end
    assign slow_clk_buf1 = slow_clk & slow_clk_buf_reg1;
    assign slow_clk_buf2 = slow_clk & slow_clk_buf_reg2;

    // Fanout buffer for update_sync_slow
    reg [2:0] update_sync_slow;
    reg [2:0] update_sync_slow_buf1, update_sync_slow_buf2;
    always @(posedge slow_clk_buf1 or negedge rst_n) begin
        if (!rst_n) begin
            update_sync_slow_buf1 <= 3'b0;
        end else begin
            update_sync_slow_buf1 <= update_sync_slow;
        end
    end
    always @(posedge slow_clk_buf2 or negedge rst_n) begin
        if (!rst_n) begin
            update_sync_slow_buf2 <= 3'b0;
        end else begin
            update_sync_slow_buf2 <= update_sync_slow;
        end
    end

    // Fanout buffer for b0 (data_reg_pipeline[0])
    reg [WIDTH-1:0] data_reg_pipeline [0:1];
    reg [WIDTH-1:0] data_reg_pipeline_buf0, data_reg_pipeline_buf1;
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg_pipeline_buf0 <= {WIDTH{1'b0}};
            data_reg_pipeline_buf1 <= {WIDTH{1'b0}};
        end else begin
            data_reg_pipeline_buf0 <= data_reg_pipeline[0];
            data_reg_pipeline_buf1 <= data_reg_pipeline[1];
        end
    end

    // Fanout buffer for i (pipeline index)
    integer i;
    reg [1:0] i_buf;
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            i_buf <= 2'b00;
        end else begin
            i_buf <= 2'b01;
        end
    end

    // Fast clock domain toggle and data register
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            update_toggle_fast <= 1'b0;
            data_reg_fast <= {WIDTH{1'b0}};
        end else if (update_fast) begin
            update_toggle_fast <= ~update_toggle_fast;
            data_reg_fast <= data_fast;
        end
    end

    // Slow clock domain: synchronize toggle and pipeline the data register
    reg update_toggle_meta1, update_toggle_meta2;
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            update_toggle_meta1 <= 1'b0;
            update_toggle_meta2 <= 1'b0;
        end else begin
            update_toggle_meta1 <= update_toggle_fast;
            update_toggle_meta2 <= update_toggle_meta1;
        end
    end

    // Pipeline data register into slow domain
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 2; i = i + 1)
                data_reg_pipeline[i] <= {WIDTH{1'b0}};
        end else begin
            data_reg_pipeline[0] <= data_reg_fast;
            data_reg_pipeline[1] <= data_reg_pipeline[0];
        end
    end

    // Synchronizer for toggle and multicycle wait
    reg update_slow_pending;
    reg [$clog2(CYCLES):0] cycle_counter_slow;
    reg [WIDTH-1:0] data_reg_slow;
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            update_sync_slow <= 3'b0;
            update_slow_pending <= 1'b0;
            cycle_counter_slow <= 0;
            data_reg_slow <= {WIDTH{1'b0}};
        end else begin
            update_sync_slow <= {update_sync_slow[1:0], update_toggle_meta2};
            if (update_sync_slow[2] != update_sync_slow[1])
                update_slow_pending <= 1'b1;

            if (update_slow_pending) begin
                if (cycle_counter_slow == CYCLES-1) begin
                    cycle_counter_slow <= 0;
                    update_slow_pending <= 1'b0;
                    data_reg_slow <= data_reg_pipeline_buf1;
                end else begin
                    cycle_counter_slow <= cycle_counter_slow + 1'b1;
                end
            end
        end
    end

    // Output register moved forward (register retiming)
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_slow <= {WIDTH{1'b0}};
        end else begin
            data_slow <= data_reg_slow;
        end
    end

endmodule