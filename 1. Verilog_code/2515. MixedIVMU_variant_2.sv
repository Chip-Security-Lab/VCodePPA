//SystemVerilog
module MixedIVMU (
    input clk, rst_n,
    input [3:0] sync_irq,
    input [3:0] async_irq,
    input ack, // Corresponds to the 'ack' signal in Req-Ack
    output reg [31:0] vector,
    output wire req // Corresponds to the 'req' signal in Req-Ack
);
    reg [31:0] vectors [0:7];
    reg [3:0] sync_pending, async_latched;
    reg [3:0] async_prev;
    wire [3:0] async_edge;
    integer i;

    // Initialize vector table
    initial begin
        vectors[0] = 32'hD000_0000;
        vectors[1] = 32'hD000_0080;
        vectors[2] = 32'hD000_0100;
        vectors[3] = 32'hD000_0180;
        vectors[4] = 32'hD000_0200;
        vectors[5] = 32'hD000_0280;
        vectors[6] = 32'hD000_0300;
        vectors[7] = 32'hD000_0380;
    end

    // Asynchronous edge detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            async_prev <= 4'h0;
        end else begin
            async_prev <= async_irq;
        end
    end

    // Calculate rising edge of asynchronous interrupts
    assign async_edge = async_irq & ~async_prev;

    // Main state logic for pending interrupts and vector selection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_pending <= 4'h0;
            async_latched <= 4'h0;
            vector <= 32'h0; // Default or reset value for vector
        end else begin
            // Latch new asynchronous edges and accumulate synchronous interrupts
            async_latched <= async_latched | async_edge;
            sync_pending <= sync_pending | sync_irq;

            // Clear pending interrupts if the request is acknowledged
            if (req && ack) begin // Handshake completion: req is high and ack is high
                sync_pending <= 4'h0;
                async_latched <= 4'h0;
                // vector is implicitly updated to 0 or next pending vector in the following logic
            end else begin
                // Select the vector for the highest priority pending interrupt
                // This logic determines the 'data' (vector) associated with the 'req' signal
                if (async_latched[3]) begin
                    vector <= vectors[7];
                end else if (async_latched[2]) begin
                    vector <= vectors[6];
                end else if (async_latched[1]) begin
                    vector <= vectors[5];
                end else if (async_latched[0]) begin
                    vector <= vectors[4];
                end else if (sync_pending[3]) begin
                    vector <= vectors[3];
                end else if (sync_pending[2]) begin
                    vector <= vectors[2];
                end else if (sync_pending[1]) begin
                    vector <= vectors[1];
                end else if (sync_pending[0]) begin
                    vector <= vectors[0];
                end else begin
                    // If no interrupts are pending, the vector might hold the last value
                    // or transition to a default value. Retaining the last value is common.
                    // The 'req' signal indicates when 'vector' is valid.
                end
            end
        end
    end

    // The 'req' signal indicates that there is a pending interrupt and 'vector' is valid
    assign req = (|sync_pending | |async_latched);

endmodule