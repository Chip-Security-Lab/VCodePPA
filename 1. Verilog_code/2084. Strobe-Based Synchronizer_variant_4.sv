//SystemVerilog
module strobe_sync (
    input wire clk_a,
    input wire clk_b,
    input wire reset,
    input wire data_a,
    input wire strobe_a,
    output reg data_b,
    output reg strobe_b
);

// Source domain registers
reg data_a_captured;
reg toggle_a;

// Synchronizer registers in destination domain
reg toggle_a_meta;
reg toggle_a_sync;
reg toggle_a_delay;

// Internal wire for strobe detection in destination domain
wire strobe_b_next;

// Source domain: Data capture
always @(posedge clk_a or posedge reset) begin
    if (reset) begin
        data_a_captured <= 1'b0;
    end else if (strobe_a) begin
        data_a_captured <= data_a;
    end
end

// Source domain: Toggle generation
always @(posedge clk_a or posedge reset) begin
    if (reset) begin
        toggle_a <= 1'b0;
    end else if (strobe_a) begin
        toggle_a <= ~toggle_a;
    end
end

// Destination domain: First synchronizer stage
always @(posedge clk_b or posedge reset) begin
    if (reset) begin
        toggle_a_meta <= 1'b0;
    end else begin
        toggle_a_meta <= toggle_a;
    end
end

// Destination domain: Second synchronizer stage
always @(posedge clk_b or posedge reset) begin
    if (reset) begin
        toggle_a_sync <= 1'b0;
    end else begin
        toggle_a_sync <= toggle_a_meta;
    end
end

// Destination domain: Delay stage
always @(posedge clk_b or posedge reset) begin
    if (reset) begin
        toggle_a_delay <= 1'b0;
    end else begin
        toggle_a_delay <= toggle_a_sync;
    end
end

// Destination domain: Strobe generation combinational logic
assign strobe_b_next = toggle_a_sync ^ toggle_a_delay;

// Destination domain: Strobe output
always @(posedge clk_b or posedge reset) begin
    if (reset) begin
        strobe_b <= 1'b0;
    end else begin
        strobe_b <= strobe_b_next;
    end
end

// Destination domain: Data output
always @(posedge clk_b or posedge reset) begin
    if (reset) begin
        data_b <= 1'b0;
    end else if (strobe_b_next) begin
        data_b <= data_a_captured;
    end
end

endmodule