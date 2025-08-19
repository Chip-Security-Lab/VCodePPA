//SystemVerilog
module MuxDemux #(parameter W=8) (
    input [W-1:0] tx_data,
    output [3:0][W-1:0] rx_data,
    input [1:0] mode,
    input dir
);

    // Data path registers
    reg [W-1:0] tx_data_reg;
    reg [1:0] mode_reg;
    reg dir_reg;
    
    // Pipeline stage 1: Input registration
    always @(*) begin
        tx_data_reg = tx_data;
        mode_reg = mode;
        dir_reg = dir;
    end
    
    // Pipeline stage 2: Data processing with barrel shifter
    reg [3:0][W-1:0] rx_data_reg;
    wire [W-1:0] shifted_data;
    
    // Barrel shifter implementation
    assign shifted_data = (mode_reg[0]) ? {tx_data_reg[3:0], tx_data_reg[W-1:4]} : tx_data_reg;
    
    always @(*) begin
        if (dir_reg) begin
            case (mode_reg)
                2'b00: rx_data_reg = {4{tx_data_reg}};
                2'b01: rx_data_reg = {tx_data_reg, shifted_data};
                default: rx_data_reg = 0;
            endcase
        end else begin
            rx_data_reg = 0;
        end
    end
    
    // Output assignment
    assign rx_data = rx_data_reg;

endmodule