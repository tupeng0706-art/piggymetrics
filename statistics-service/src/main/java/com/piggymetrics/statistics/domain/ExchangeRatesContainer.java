package com.piggymetrics.statistics.domain;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;

@JsonIgnoreProperties(ignoreUnknown = true, value = {"date"})
public class ExchangeRatesContainer {

	private Map<String, BigDecimal> defaultRates = new HashMap<String, BigDecimal>() {{
		put("USD", new BigDecimal("1.0"));
		put("EUR", new BigDecimal("0.92"));
		put("CNY", new BigDecimal("7.25"));
		put("GBP", new BigDecimal("0.78"));
		put("RUB", new BigDecimal("0.58"));
	}};

	private LocalDate date = LocalDate.now();

	private Currency base;

	private Map<String, BigDecimal> rates;

	public LocalDate getDate() {
		return date;
	}

	public void setDate(LocalDate date) {
		this.date = date;
	}

	public Currency getBase() {
		return base;
	}

	public void setBase(Currency base) {
		this.base = base;
	}

	public Map<String, BigDecimal> getRates() {
        if (rates == null) {
            return defaultRates;
        }
		return rates;
	}

	public void setRates(Map<String, BigDecimal> rates) {
		this.rates = rates;
	}

	@Override
	public String toString() {
		return "RateList{" +
				"date=" + date +
				", base=" + base +
				", rates=" + rates +
				'}';
	}
}
