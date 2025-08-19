//SystemVerilog
module APB_IVMU (
    input pclk, preset_n,
    input [7:0] paddr,
    input psel, penable, pwrite,
    input [31:0] pwdata,
    output reg [31:0] prdata,
    input [15:0] irq_in,
    // Original output: vector, irq_out
    // Transformed to Req-Ack interface for vector
    output reg [31:0] vector,      // Output data (Interrupt Vector)
    output wire irq_out,           // Output status (Any interrupt pending)
    output reg vector_req,        // Output Request signal for vector
    input vector_ack               // Input Acknowledge signal for vector
);

    reg [31:0] regs [0:15]; // Vector table
    reg [15:0] mask;
    wire [15:0] pending;
    wire apb_write, apb_read;
    integer i;

    // Internal registers for Req-Ack handshake state and latched vector data
    reg vector_req_reg;
    reg [31:0] vector_reg;

    // APB control signals
    assign apb_write = psel & penable & pwrite;
    assign apb_read = psel & penable & ~pwrite;

    // Pending interrupts based on input and mask
    assign pending = irq_in & ~mask;

    // irq_out signal remains the overall pending status, not part of the handshake
    assign irq_out = |pending;

    // Assign output vector from the latched register
    assign vector = vector_reg;

    // Assign output request from the internal register
    assign vector_req = vector_req_reg;

    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n) begin
            // Reset APB registers
            for (i = 0; i < 16; i = i + 1) regs[i] <= 32'hE000_0000 + (i << 8);
            mask <= 16'hFFFF;
            prdata <= 32'h0; // Reset prdata

            // Reset Req-Ack handshake state and data
            vector_req_reg <= 1'b0;
            vector_reg <= 32'h0; // Reset vector data

        end else begin
            // APB write logic
            if (apb_write) begin
                // Convert if-else if structure based on paddr to case statement
                case (paddr)
                    8'h00: regs[0] <= pwdata;
                    8'h01: regs[1] <= pwdata;
                    8'h02: regs[2] <= pwdata;
                    8'h03: regs[3] <= pwdata;
                    8'h04: regs[4] <= pwdata;
                    8'h05: regs[5] <= pwdata;
                    8'h06: regs[6] <= pwdata;
                    8'h07: regs[7] <= pwdata;
                    8'h08: regs[8] <= pwdata;
                    8'h09: regs[9] <= pwdata;
                    8'h0A: regs[10] <= pwdata;
                    8'h0B: regs[11] <= pwdata;
                    8'h0C: regs[12] <= pwdata;
                    8'h0D: regs[13] <= pwdata;
                    8'h0E: regs[14] <= pwdata;
                    8'h0F: regs[15] <= pwdata;
                    8'h40: mask <= pwdata[15:0];
                    default: ; // No action for other addresses on write
                endcase
            end

            // APB read logic
            if (apb_read) begin
                // Convert if-else if structure based on paddr to case statement
                case (paddr)
                    8'h00: prdata <= regs[0];
                    8'h01: prdata <= regs[1];
                    8'h02: prdata <= regs[2];
                    8'h03: prdata <= regs[3];
                    8'h04: prdata <= regs[4];
                    8'h05: prdata <= regs[5];
                    8'h06: prdata <= regs[6];
                    8'h07: prdata <= regs[7];
                    8'h08: prdata <= regs[8];
                    8'h09: prdata <= regs[9];
                    8'h0A: prdata <= regs[10];
                    8'h0B: prdata <= regs[11];
                    8'h0C: prdata <= regs[12];
                    8'h0D: prdata <= regs[13];
                    8'h0E: prdata <= regs[14];
                    8'h0F: prdata <= regs[15];
                    8'h40: prdata <= {16'h0, mask};
                    8'h44: prdata <= {16'h0, pending};
                    default: prdata <= 32'h0; // Default read value
                endcase
            end

            // Req-Ack handshake logic for vector
            // vector_req_reg state transitions
            if (vector_req_reg && vector_ack) begin
                // Currently requesting and received acknowledge -> go to Idle
                vector_req_reg <= 1'b0;
            end else if (!vector_req_reg && |pending) begin
                // Currently Idle and there is a pending interrupt -> go to Requesting
                vector_req_reg <= 1'b1;

                // Latch the highest priority vector data when a new request is initiated
                // The loop iterates from highest priority (15) down to lowest (0)
                // The last assignment to vector_reg will be the highest priority one
                for (i = 15; i >= 0; i = i - 1) begin
                    if (pending[i]) begin
                        vector_reg <= regs[i]; // Latch the vector address
                    end
                end
            end
            // If vector_req_reg is high and vector_ack is low, stay in Requesting (hold data and request)
            // If vector_req_reg is low and |pending is low, stay in Idle
        end
    end

endmodule