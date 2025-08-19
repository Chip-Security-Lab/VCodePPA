//SystemVerilog
// Priority Interrupt Controller Top Module
module PriorityITRC #(parameter WIDTH=8) (
    input wire clk, rst_n, enable,
    input wire [WIDTH-1:0] irq_in,
    output reg [WIDTH-1:0] irq_ack,
    output reg [$clog2(WIDTH)-1:0] irq_id,
    output reg irq_valid
);

    // Internal signals
    wire irq_detected;
    wire [$clog2(WIDTH)-1:0] highest_irq_id;
    wire [WIDTH-1:0] irq_ack_next;

    // IRQ Detection Module
    IRQ_Detector #(.WIDTH(WIDTH)) irq_detector (
        .irq_in(irq_in),
        .irq_detected(irq_detected)
    );

    // Priority Encoder Module
    Priority_Encoder #(.WIDTH(WIDTH)) priority_encoder (
        .irq_in(irq_in),
        .irq_id(highest_irq_id),
        .irq_ack(irq_ack_next)
    );

    // Control Logic Module
    Control_Logic #(.WIDTH(WIDTH)) control_logic (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .irq_detected(irq_detected),
        .highest_irq_id(highest_irq_id),
        .irq_ack_next(irq_ack_next),
        .irq_ack(irq_ack),
        .irq_id(irq_id),
        .irq_valid(irq_valid)
    );

endmodule

// IRQ Detection Module
module IRQ_Detector #(parameter WIDTH=8) (
    input wire [WIDTH-1:0] irq_in,
    output wire irq_detected
);
    assign irq_detected = |irq_in;
endmodule

// Priority Encoder Module
module Priority_Encoder #(parameter WIDTH=8) (
    input wire [WIDTH-1:0] irq_in,
    output reg [$clog2(WIDTH)-1:0] irq_id,
    output reg [WIDTH-1:0] irq_ack
);
    // Internal signals
    reg found;
    reg [WIDTH-1:0] irq_mask;
    
    // Priority ID generation
    always @(*) begin
        irq_id = 0;
        found = 0;
        for (int i = WIDTH-1; i >= 0; i--) begin
            if (irq_in[i] && !found) begin
                irq_id = i[$clog2(WIDTH)-1:0];
                found = 1;
            end
        end
    end
    
    // Acknowledge signal generation
    always @(*) begin
        irq_ack = 0;
        if (found) begin
            irq_ack[irq_id] = 1;
        end
    end
endmodule

// Control Logic Module
module Control_Logic #(parameter WIDTH=8) (
    input wire clk, rst_n, enable,
    input wire irq_detected,
    input wire [$clog2(WIDTH)-1:0] highest_irq_id,
    input wire [WIDTH-1:0] irq_ack_next,
    output reg [WIDTH-1:0] irq_ack,
    output reg [$clog2(WIDTH)-1:0] irq_id,
    output reg irq_valid
);
    // Reset logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            irq_ack <= 0;
            irq_id <= 0;
            irq_valid <= 0;
        end
    end
    
    // Control logic
    always @(posedge clk) begin
        if (rst_n && enable) begin
            irq_valid <= irq_detected;
            irq_ack <= irq_ack_next;
            irq_id <= highest_irq_id;
        end
    end
endmodule