//SystemVerilog
module slow_to_fast_sync #(parameter WIDTH = 12) (
    input wire slow_clk,
    input wire fast_clk,
    input wire rst_n,
    input wire [WIDTH-1:0] slow_data,
    output reg [WIDTH-1:0] fast_data,
    output reg data_valid
);

    // Slow domain registers
    reg slow_toggle;
    reg [WIDTH-1:0] slow_data_latched;

    // Fast domain registers
    reg [2:0] sync_toggle_ff;
    reg last_fast_toggle;
    reg [WIDTH-1:0] data_buffer;

    // Slow clock domain: toggle and latch data
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            slow_toggle <= 1'b0;
        end else begin
            slow_toggle <= ~slow_toggle;
        end
    end

    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            slow_data_latched <= {WIDTH{1'b0}};
        end else begin
            slow_data_latched <= slow_data;
        end
    end

    // Fast clock domain: 3-stage synchronizer for slow_toggle
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_toggle_ff <= 3'b000;
        end else begin
            sync_toggle_ff <= {sync_toggle_ff[1:0], slow_toggle};
        end
    end

    // Fast clock domain: edge detection for toggle
    wire toggle_edge_detected;
    assign toggle_edge_detected = (sync_toggle_ff[2] ^ last_fast_toggle);

    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            last_fast_toggle <= 1'b0;
        end else begin
            last_fast_toggle <= sync_toggle_ff[2];
        end
    end

    // Fast clock domain: latch data_buffer from slow domain
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_buffer <= {WIDTH{1'b0}};
        end else if (toggle_edge_detected) begin
            data_buffer <= slow_data_latched;
        end
    end

    // Fast clock domain: output fast_data
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            fast_data <= {WIDTH{1'b0}};
        end else if (toggle_edge_detected) begin
            fast_data <= slow_data_latched;
        end
    end

    // Fast clock domain: data_valid signal
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid <= 1'b0;
        end else begin
            data_valid <= toggle_edge_detected;
        end
    end

endmodule