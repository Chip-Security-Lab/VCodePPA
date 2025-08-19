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
    reg [15:0] pending_r; // Registered version of pending for retiming
    wire apb_write, apb_read;
    integer i;

    assign apb_write = psel & penable & pwrite;
    assign apb_read = psel & penable & ~pwrite;
    assign pending = irq_in & ~mask; // Combinational calculation

    // Combinational logic for vector calculation based on registered pending (pending_r)
    logic [3:0] highest_pending_idx; // Changed to logic for assignment in always_comb
    wire pending_r_any;
    wire [31:0] next_vector_val; // Value to load into vector register

    assign pending_r_any = |pending_r;

    // Combinational priority encoder for pending_r
    // Finds the index of the highest set bit in pending_r
    // Implemented using explicit priority structure (if/else if)
    always_comb begin
        highest_pending_idx = 4'd0; // Default value
        if (pending_r[15]) highest_pending_idx = 4'd15;
        else if (pending_r[14]) highest_pending_idx = 4'd14;
        else if (pending_r[13]) highest_pending_idx = 4'd13;
        else if (pending_r[12]) highest_pending_idx = 4'd12;
        else if (pending_r[11]) highest_pending_idx = 4'd11;
        else if (pending_r[10]) highest_pending_idx = 4'd10;
        else if (pending_r[9])  highest_pending_idx = 4'd9;
        else if (pending_r[8])  highest_pending_idx = 4'd8;
        else if (pending_r[7])  highest_pending_idx = 4'd7;
        else if (pending_r[6])  highest_pending_idx = 4'd6;
        else if (pending_r[5])  highest_pending_idx = 4'd5;
        else if (pending_r[4])  highest_pending_idx = 4'd4;
        else if (pending_r[3])  highest_pending_idx = 4'd3;
        else if (pending_r[2])  highest_pending_idx = 4'd2;
        else if (pending_r[1])  highest_pending_idx = 4'd1;
        else if (pending_r[0])  highest_pending_idx = 4'd0; // Explicitly assign 0 if pending_r[0] is set
    end

    // Combinational lookup from regs based on the highest index
    // This lookup must be combinational here as it feeds the next_vector_val wire
    assign next_vector_val = regs[highest_pending_idx];


    always @(posedge pclk or negedge preset_n) begin
        if (!preset_n) begin
            // Reset logic
            for (i = 0; i < 16; i = i + 1) regs[i] <= 32'hE000_0000 + (i << 8);
            mask <= 16'hFFFF;
            prdata <= 32'h0; // Reset prdata
            vector <= 32'h0; // Reset vector
            irq_out <= 1'b0; // Reset irq_out
            pending_r <= 16'h0; // Reset pending_r
        end else begin
            // Register pending for next cycle's interrupt logic
            pending_r <= pending;

            // APB write logic (remains the same)
            if (apb_write) begin
                if (paddr[7:4] == 0) regs[paddr[3:0]] <= pwdata;
                else if (paddr == 8'h40) mask <= pwdata[15:0];
            end

            // APB read logic (remains the same, uses current pending for addr 8'h44 to maintain APB latency)
            if (apb_read) begin
                if (paddr[7:4] == 0) prdata <= regs[paddr[3:0]];
                else if (paddr == 8'h40) prdata <= {16'h0, mask};
                else if (paddr == 8'h44) prdata <= {16'h0, pending}; // Uses current pending
            end

            // Update irq_out based on registered pending (delayed by 1 cycle relative to pending)
            irq_out <= |pending_r;

            // Update vector based on registered pending (delayed by 1 cycle relative to pending)
            // Only update vector if there is any pending_r interrupt, matching original behavior
            if (pending_r_any) begin
                 vector <= next_vector_val; // Load the pre-calculated value from combinational logic
            end
            // If !pending_r_any, vector holds its previous value, matching original behavior
        end
    end
endmodule