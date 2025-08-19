//SystemVerilog
//-----------------------------------------------------------------------------
// Top-level Module: Double Buffered Shadow Register with Pipeline Architecture
//-----------------------------------------------------------------------------
module shadow_reg_double_buf #(
    parameter WIDTH = 16,
    parameter PIPELINE_STAGES = 3
)(
    input wire clk,
    input wire rst_n,
    input wire swap,
    input wire valid_in,
    input wire [WIDTH-1:0] update_data,
    output wire [WIDTH-1:0] active_data,
    output wire valid_out
);

    // Pipeline stage signals for data
    reg [WIDTH-1:0] update_data_stage1, update_data_stage2;
    wire [WIDTH-1:0] buffer_data;
    wire [WIDTH-1:0] active_data_int;
    
    // Pipeline valid signals
    reg valid_stage1, valid_stage2;
    reg swap_stage1, swap_stage2;
    
    // Pipeline stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            update_data_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
            swap_stage1 <= 1'b0;
        end else begin
            update_data_stage1 <= update_data;
            valid_stage1 <= valid_in;
            swap_stage1 <= swap;
        end
    end
    
    // Pipeline stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            update_data_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
            swap_stage2 <= 1'b0;
        end else begin
            update_data_stage2 <= update_data_stage1;
            valid_stage2 <= valid_stage1;
            swap_stage2 <= swap_stage1;
        end
    end

    // Buffer Register submodule
    buffer_register #(
        .WIDTH(WIDTH)
    ) u_buffer_reg (
        .clk(clk),
        .rst_n(rst_n),
        .swap(swap_stage2),
        .valid_in(valid_stage2),
        .update_data(update_data_stage2),
        .buffer_data(buffer_data),
        .valid_out(buffer_valid)
    );

    // Active Register submodule
    active_register #(
        .WIDTH(WIDTH)
    ) u_active_reg (
        .clk(clk),
        .rst_n(rst_n),
        .swap(swap_stage2),
        .valid_in(buffer_valid),
        .buffer_data(buffer_data),
        .active_data(active_data_int),
        .valid_out(valid_out)
    );

    // Output assignment
    assign active_data = active_data_int;

endmodule

//-----------------------------------------------------------------------------
// Buffer Register Module - Handles update path with pipelining
//-----------------------------------------------------------------------------
module buffer_register #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire swap,
    input wire valid_in,
    input wire [WIDTH-1:0] update_data,
    output reg [WIDTH-1:0] buffer_data,
    output reg valid_out
);

    // Internal pipeline stage
    reg [WIDTH-1:0] buffer_data_next;
    reg valid_internal;

    // First pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_data_next <= {WIDTH{1'b0}};
            valid_internal <= 1'b0;
        end else begin
            if (valid_in && !swap) begin
                buffer_data_next <= update_data;
                valid_internal <= 1'b1;
            end else begin
                valid_internal <= 1'b0;
            end
        end
    end

    // Second pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_data <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            if (valid_internal) begin
                buffer_data <= buffer_data_next;
            end
            valid_out <= valid_internal;
        end
    end

endmodule

//-----------------------------------------------------------------------------
// Active Register Module - Handles swap operation with pipelining
//-----------------------------------------------------------------------------
module active_register #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire swap,
    input wire valid_in,
    input wire [WIDTH-1:0] buffer_data,
    output reg [WIDTH-1:0] active_data,
    output reg valid_out
);

    // Internal pipeline registers
    reg [WIDTH-1:0] active_data_next;
    reg valid_internal;

    // First pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active_data_next <= {WIDTH{1'b0}};
            valid_internal <= 1'b0;
        end else begin
            if (valid_in && swap) begin
                active_data_next <= buffer_data;
                valid_internal <= 1'b1;
            end else begin
                valid_internal <= 1'b0;
            end
        end
    end

    // Second pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active_data <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            if (valid_internal) begin
                active_data <= active_data_next;
            end
            valid_out <= valid_internal;
        end
    end

endmodule