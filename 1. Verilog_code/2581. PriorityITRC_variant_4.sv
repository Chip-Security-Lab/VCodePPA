//SystemVerilog
module PriorityITRC #(parameter WIDTH=8) (
    input wire clk, rst_n, enable,
    input wire [WIDTH-1:0] irq_in,
    output reg [WIDTH-1:0] irq_ack,
    output reg [$clog2(WIDTH)-1:0] irq_id,
    output reg irq_valid
);

    wire irq_detected;
    wire [$clog2(WIDTH)-1:0] encoded_id;
    wire [WIDTH-1:0] encoded_ack;

    IRQDetector #(.WIDTH(WIDTH)) detector (
        .irq_in(irq_in),
        .irq_detected(irq_detected)
    );

    PriorityEncoder #(.WIDTH(WIDTH)) encoder (
        .irq_in(irq_in),
        .encoded_id(encoded_id),
        .encoded_ack(encoded_ack)
    );

    IRQResponse #(.WIDTH(WIDTH)) response (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .irq_detected(irq_detected),
        .encoded_id(encoded_id),
        .encoded_ack(encoded_ack),
        .irq_ack(irq_ack),
        .irq_id(irq_id),
        .irq_valid(irq_valid)
    );

endmodule

module IRQDetector #(parameter WIDTH=8) (
    input wire [WIDTH-1:0] irq_in,
    output wire irq_detected
);
    assign irq_detected = |irq_in;
endmodule

module PriorityEncoder #(parameter WIDTH=8) (
    input wire [WIDTH-1:0] irq_in,
    output reg [$clog2(WIDTH)-1:0] encoded_id,
    output reg [WIDTH-1:0] encoded_ack
);
    
    reg [WIDTH-1:0] priority_mask;
    reg [$clog2(WIDTH)-1:0] temp_id;
    
    always @(*) begin
        priority_mask = irq_in & (~irq_in + 1);
        temp_id = 0;
        for (int i = 0; i < WIDTH; i++) begin
            if (priority_mask[i]) begin
                temp_id = i;
            end
        end
    end
    
    always @(*) begin
        encoded_id = temp_id;
        encoded_ack = priority_mask;
    end
endmodule

module IRQResponse #(parameter WIDTH=8) (
    input wire clk, rst_n, enable,
    input wire irq_detected,
    input wire [$clog2(WIDTH)-1:0] encoded_id,
    input wire [WIDTH-1:0] encoded_ack,
    output reg [WIDTH-1:0] irq_ack,
    output reg [$clog2(WIDTH)-1:0] irq_id,
    output reg irq_valid
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            irq_valid <= 0;
        end else if (enable) begin
            irq_valid <= irq_detected;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            irq_ack <= 0;
        end else if (enable) begin
            irq_ack <= encoded_ack;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            irq_id <= 0;
        end else if (enable) begin
            irq_id <= encoded_id;
        end
    end
endmodule