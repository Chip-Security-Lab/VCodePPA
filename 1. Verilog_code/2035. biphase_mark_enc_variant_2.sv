//SystemVerilog
module biphase_mark_enc (
    input        clk,
    input        rst_n,
    input        data_in,
    output reg   encoded
);

    reg          phase_q;
    reg          data_in_d;
    reg          encoded_d;

    //=========================================================
    // Phase Register Update Logic
    // Handles phase_q toggling on each clock cycle
    //=========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            phase_q <= 1'b0;
        else
            phase_q <= ~phase_q;
    end

    //=========================================================
    // Data Input Registering Logic
    // Handles data_in_d capturing on each clock cycle
    //=========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_in_d <= 1'b0;
        else
            data_in_d <= data_in;
    end

    //=========================================================
    // Encoded Data Combinational Logic
    // Computes encoded_d based on data_in_d and phase_q
    //=========================================================
    always @(*) begin
        if (data_in_d)
            encoded_d = phase_q;
        else
            encoded_d = ~phase_q;
    end

    //=========================================================
    // Encoded Output Registering Logic
    // Registers the encoded_d value to the output
    //=========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            encoded <= 1'b0;
        else
            encoded <= encoded_d;
    end

endmodule