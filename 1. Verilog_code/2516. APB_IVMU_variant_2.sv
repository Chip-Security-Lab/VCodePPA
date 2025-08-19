//SystemVerilog
module APB_IVMU (
    input pclk, preset_n,
    input [7:0] paddr,
    input psel, penable, pwrite,
    input [31:0] pwdata,
    output reg [31:0] prdata,
    input [15:0] irq_in,
    output reg [31:0] vector,
    output reg irq_out
);
    reg [31:0] regs [0:15]; // Vector table
    reg [15:0] mask;
    wire [15:0] pending;
    wire apb_write, apb_read;
    integer i;

    // Combinatorial signals for APB address decoding
    wire paddr_is_regs_range = (paddr[7:4] == 4'h0);
    wire paddr_is_mask_reg = (paddr == 8'h40);
    wire paddr_is_pending_reg = (paddr == 8'h44);

    // APB control signals (combinatorial)
    assign apb_write = psel & penable & pwrite;
    assign apb_read = psel & penable & ~pwrite;

    // Calculate pending IRQs (combinatorial)
    assign pending = irq_in & ~mask;

    // Combinatorial priority encoder for pending IRQs
    // Finds the index (0-15) of the highest set bit in 'pending'
    // Transformed from ternary operator chain to if-else if structure
    reg [3:0] pending_high_idx; // Changed from wire to reg for always @* block
    wire pending_any = |pending; // Check if any IRQ is pending

    // Priority encoder logic using if-else if structure
    always @* begin
        if (pending[15])
            pending_high_idx = 4'd15;
        else if (pending[14])
            pending_high_idx = 4'd14;
        else if (pending[13])
            pending_high_idx = 4'd13;
        else if (pending[12])
            pending_high_idx = 4'd12;
        else if (pending[11])
            pending_high_idx = 4'd11;
        else if (pending[10])
            pending_high_idx = 4'd10;
        else if (pending[9])
            pending_high_idx = 4'd9;
        else if (pending[8])
            pending_high_idx = 4'd8;
        else if (pending[7])
            pending_high_idx = 4'd7;
        else if (pending[6])
            pending_high_idx = 4'd6;
        else if (pending[5])
            pending_high_idx = 4'd5;
        else if (pending[4])
            pending_high_idx = 4'd4;
        else if (pending[3])
            pending_high_idx = 4'd3;
        else if (pending[2])
            pending_high_idx = 4'd2;
        else if (pending[1])
            pending_high_idx = 4'd1;
        else // Default index if no bit is set (corresponds to pending[0] or all zeros)
            pending_high_idx = 4'd0;
    end


    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n) begin
            // Reset logic: Initialize registers and state
            for (i = 0; i < 16; i = i + 1) begin
                regs[i] <= 32'hE000_0000 + (i << 8); // Initialize vector table entries
            end
            mask <= 16'hFFFF; // Mask all IRQs by default
            irq_out <= 1'b0; // No IRQ asserted
            vector <= 32'hE000_0000; // Reset vector to address of regs[0]
            prdata <= 32'h0; // Reset read data output
        end else begin
            // APB Write Logic
            // Updates registers based on paddr when apb_write is active
            // Uses if-else if structure to reflect address priority (if any)
            if (apb_write) begin
                if (paddr_is_regs_range) begin
                    regs[paddr[3:0]] <= pwdata; // Write to vector table entry
                end else if (paddr_is_mask_reg) begin
                    mask <= pwdata[15:0]; // Write to mask register
                end
                // Writes to unmapped addresses are ignored
            end

            // APB Read Logic
            // Sets prdata based on paddr when apb_read is active
            // Uses if-else if structure to reflect address priority (if any)
            if (apb_read) begin
                if (paddr_is_regs_range) begin
                    prdata <= regs[paddr[3:0]]; // Read from vector table entry
                end else if (paddr_is_mask_reg) begin
                    prdata <= {16'h0, mask}; // Read mask register
                end else if (paddr_is_pending_reg) begin
                    prdata <= {16'h0, pending}; // Read pending register
                end
                // For unmapped addresses, prdata holds its previous value
            end

            // IRQ Logic
            // irq_out is asserted if any IRQ is pending (registered)
            irq_out <= pending_any;

            // Update vector with the address of the highest pending IRQ handler
            // Only update vector if there is at least one pending IRQ
            // This uses the result of the combinatorial priority encoder
            if (pending_any) begin
                vector <= regs[pending_high_idx];
            end
            // If no IRQ is pending, vector holds its previous value
        end
    end

endmodule