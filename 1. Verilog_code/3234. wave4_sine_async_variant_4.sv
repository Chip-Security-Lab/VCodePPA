//SystemVerilog
module wave4_sine_async #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 8
)(
    input  wire clk,       // Added clock
    input  wire rst_n,     // Added active-low reset
    input  wire [ADDR_WIDTH-1:0] addr,
    output wire [DATA_WIDTH-1:0] wave_out
);

    (* ram_style = "distributed" *) reg [DATA_WIDTH-1:0] rom [0:(1<<ADDR_WIDTH)-1];
    reg [DATA_WIDTH-1:0] data_reg;

    // State machine for ROM initialization
    localparam [1:0]
        S_IDLE     = 2'b00,
        S_INIT_ROM = 2'b01,
        S_DONE     = 2'b10;

    reg [1:0] current_state, next_state;
    reg [ADDR_WIDTH-1:0] init_addr;
    reg init_write_en; // Control signal for writing to ROM during initialization

    // State and counter registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= S_IDLE;
            init_addr <= 0;
        end else begin
            current_state <= next_state;
            if (current_state == S_INIT_ROM && init_write_en) begin
                 init_addr <= init_addr + 1;
            end else begin
                 init_addr <= 0; // Reset counter on state change from IDLE/DONE to INIT
            end
        end
    end

    // Next state logic and control signals
    always @(*) begin
        next_state = current_state;
        init_write_en = 0;

        case (current_state)
            S_IDLE: begin
                next_state = S_INIT_ROM; // Start initialization after reset release
            end

            S_INIT_ROM: begin
                init_write_en = 1; // Enable write for the current address
                if (init_addr == (1<<ADDR_WIDTH) - 1) begin
                    next_state = S_DONE; // Move to DONE after writing the last address
                end else begin
                    next_state = S_INIT_ROM; // Stay in INIT until done
                end
            end

            S_DONE: begin
                next_state = S_DONE; // Stay in DONE
            end

            default: begin
                next_state = S_IDLE; // Should not happen
            end
        endcase
    end

    // ROM write logic (during initialization)
    always @(posedge clk) begin
        if (current_state == S_INIT_ROM && init_write_en) begin
            rom[init_addr] <= init_addr % (1<<DATA_WIDTH);
        end
    end

    // Asynchronous ROM read logic (same as original)
    always @(addr) begin
        data_reg = rom[addr];
    end

    // Output assignment (same as original)
    assign wave_out = data_reg;

endmodule